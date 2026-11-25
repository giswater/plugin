/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION publi.gw_fct_publi_seed_config(p_data json)
RETURNS json AS
$BODY$

/*example
SELECT publi.gw_fct_publi_seed_config($${"data":{"sourceSchema":"ws", "prefix":"ws", "replace":false}}$$);

Fills publi.config_publi_table for one source schema (DESIGN 4):
  parents, children that add columns over their parent, EPA (ve_inp_*), mapzones, municipality, catalogs,
  doc + unified doc_x_feature, corporate EPA results, mincut, minsector_mincut.
Only objects that exist in the source are added. Each candidate is probed (LIMIT 0) to resolve the pk and the
rls mode (expl_id -> expl, sector_id -> sector, otherwise none). Existing rows are kept unless "replace":true.
*/

DECLARE
	v_schema text;
	v_prefix text;
	v_replace boolean;
	v_rec record;
	v_src text;
	v_cols text[];
	v_pk text[];
	v_rls text;
	v_parts text[];
	v_lateral text[];
	v_doccols text;
	v_where text;
	v_added jsonb := '[]';
	v_skipped jsonb := '[]';
	v_count int;
	v_col text;
	v_unique boolean;
BEGIN
	v_schema := p_data -> 'data' ->> 'sourceSchema';
	v_prefix := COALESCE(p_data -> 'data' ->> 'prefix', v_schema);
	v_replace := COALESCE((p_data -> 'data' ->> 'replace')::boolean, false);

	IF v_schema IS NULL OR to_regnamespace(v_schema) IS NULL THEN
		RAISE EXCEPTION 'sourceSchema % does not exist', v_schema;
	END IF;

	DROP TABLE IF EXISTS pg_temp.publi_seed;
	CREATE TEMP TABLE publi_seed (
		source_relation text,
		source_sql text,
		target_name text,
		object_type text,
		pk_columns text[],
		alias_custom text,
		where_clause text,
		rls_mode text,
		decode_columns boolean DEFAULT true,
		sync_frequency text DEFAULT 'daily',
		orderby int
	);

	-- parents
	INSERT INTO publi_seed (source_relation, target_name, object_type, pk_columns, orderby)
	SELECT rel, v_prefix || '_' || substr(rel, 4), 'parent', ARRAY[pk], 10
	FROM (VALUES ('ve_arc', 'arc_id'), ('ve_node', 'node_id'), ('ve_connec', 'connec_id'),
		('ve_gully', 'gully_id'), ('ve_link', 'link_id'), ('ve_element', 'element_id')) t(rel, pk)
	WHERE to_regclass(format('%I.%I', v_schema, rel)) IS NOT NULL;

	-- children: only those adding columns over their parent
	IF to_regclass(format('%I.cat_feature', v_schema)) IS NOT NULL THEN
		FOR v_rec IN EXECUTE format(
			$q$SELECT child_layer, parent_layer, upper(feature_type) AS feature_type
			FROM %I.cat_feature WHERE active AND child_layer IS NOT NULL$q$, v_schema)
		LOOP
			IF to_regclass(format('%I.%I', v_schema, v_rec.child_layer)) IS NULL THEN
				CONTINUE;
			END IF;

			IF v_rec.parent_layer IS NOT NULL AND to_regclass(format('%I.%I', v_schema, v_rec.parent_layer)) IS NOT NULL
			AND NOT EXISTS (
				SELECT 1 FROM pg_attribute c
				WHERE c.attrelid = format('%I.%I', v_schema, v_rec.child_layer)::regclass
				AND c.attnum > 0 AND NOT c.attisdropped
				AND c.attname NOT IN (
					SELECT p.attname FROM pg_attribute p
					WHERE p.attrelid = format('%I.%I', v_schema, v_rec.parent_layer)::regclass
					AND p.attnum > 0 AND NOT p.attisdropped))
			THEN
				v_skipped := v_skipped || jsonb_build_object('source', v_rec.child_layer, 'reason', 'no columns over parent');
				CONTINUE;
			END IF;

			INSERT INTO publi_seed (source_relation, target_name, object_type, pk_columns, orderby)
			VALUES (v_rec.child_layer, v_prefix || '_' || substr(v_rec.child_layer, 4), 'child',
				CASE v_rec.feature_type
					WHEN 'ARC' THEN '{arc_id}'::text[] WHEN 'NODE' THEN '{node_id}' WHEN 'CONNEC' THEN '{connec_id}'
					WHEN 'GULLY' THEN '{gully_id}' WHEN 'LINK' THEN '{link_id}' WHEN 'ELEMENT' THEN '{element_id}'
				END, 20);
		END LOOP;
	END IF;

	-- EPA: pk resolved from the probe
	INSERT INTO publi_seed (source_relation, target_name, object_type, orderby)
	SELECT c.relname, v_prefix || '_' || substr(c.relname, 4), 'epa', 30
	FROM pg_class c
	WHERE c.relnamespace = to_regnamespace(v_schema)
	AND c.relkind IN ('v', 'r', 'm')
	AND c.relname LIKE 've\_inp\_%'
	AND c.relname NOT LIKE '%dscenario%';

	-- mapzones and municipality: ve_ view if it exists, else the table
	INSERT INTO publi_seed (source_relation, target_name, object_type, pk_columns, orderby)
	SELECT CASE WHEN to_regclass(format('%I.%I', v_schema, 've_' || zone)) IS NOT NULL THEN 've_' || zone ELSE zone END,
		v_prefix || '_' || target, 'mapzone', ARRAY[pk], 40
	FROM (VALUES
		('macroexploitation', 'macroexpl_id', 'macroexploitation'),
		('exploitation', 'expl_id', 'exploitation'),
		('macrosector', 'macrosector_id', 'macrosector'),
		('sector', 'sector_id', 'sector'),
		('macrodma', 'macrodma_id', 'macrodma'),
		('dma', 'dma_id', 'dma'),
		('macrodqa', 'macrodqa_id', 'macrodqa'),
		('dqa', 'dqa_id', 'dqa'),
		('presszone', 'presszone_id', 'presszone'),
		('supplyzone', 'supplyzone_id', 'supplyzone'),
		('macroomzone', 'macroomzone_id', 'macroomzone'),
		('omzone', 'omzone_id', 'omzone'),
		('minsector', 'minsector_id', 'minsector'),
		('drainzone', 'drainzone_id', 'drainzone'),
		('dwfzone', 'dwfzone_id', 'dwfzone'),
		('ext_municipality', 'muni_id', 'municipality')
	) t(zone, pk, target)
	WHERE to_regclass(format('%I.%I', v_schema, zone)) IS NOT NULL
	OR to_regclass(format('%I.%I', v_schema, 've_' || zone)) IS NOT NULL;

	-- catalogs: pk from the table, no rls
	INSERT INTO publi_seed (source_relation, target_name, object_type, rls_mode, orderby)
	SELECT cat, v_prefix || '_' || cat, 'catalog', 'none', 50
	FROM unnest(ARRAY['cat_arc', 'cat_node', 'cat_connec', 'cat_gully', 'cat_link', 'cat_element', 'cat_material',
		'cat_brand', 'cat_brand_model', 'cat_owner', 'cat_work', 'cat_feature', 'cat_soil', 'cat_pavement']) cat
	WHERE to_regclass(format('%I.%I', v_schema, cat)) IS NOT NULL;

	-- documents
	IF to_regclass(format('%I.doc', v_schema)) IS NOT NULL THEN
		INSERT INTO publi_seed (source_relation, target_name, object_type, rls_mode, orderby)
		VALUES ('doc', v_prefix || '_doc', 'doc', 'none', 60);

		v_parts := '{}';
		v_lateral := '{}';
		FOR v_rec IN
			SELECT c.relname::text AS rel, substr(c.relname, 7) AS suffix
			FROM pg_class c
			WHERE c.relnamespace = to_regnamespace(v_schema) AND c.relkind = 'r' AND c.relname LIKE 'doc\_x\_%'
			AND EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'doc_id')
			AND EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = substr(c.relname, 7) || '_id')
			ORDER BY c.relname
		LOOP
			v_parts := v_parts || format('SELECT doc_id, %L::text AS feature_type, %I::text AS feature_id FROM %I.%I',
				upper(v_rec.suffix), v_rec.suffix || '_id', v_schema, v_rec.rel);

			-- expl_id of the linked object, for rls
			v_src := CASE WHEN v_rec.suffix = 'psector' THEN 'plan_psector' ELSE v_rec.suffix END;
			IF to_regclass(format('%I.%I', v_schema, v_src)) IS NOT NULL
			AND EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = format('%I.%I', v_schema, v_src)::regclass AND attname = 'expl_id')
			AND EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = format('%I.%I', v_schema, v_src)::regclass AND attname = v_rec.suffix || '_id')
			THEN
				v_lateral := v_lateral || format('SELECT expl_id FROM %I.%I WHERE x.feature_type = %L AND %I::text = x.feature_id',
					v_schema, v_src, upper(v_rec.suffix), v_rec.suffix || '_id');
			END IF;
		END LOOP;

		IF cardinality(v_parts) > 0 THEN
			SELECT string_agg(format('d.%I', attname), ', ' ORDER BY attnum) INTO v_doccols
			FROM pg_attribute
			WHERE attrelid = format('%I.doc', v_schema)::regclass AND attnum > 0 AND NOT attisdropped
			AND attname NOT IN ('id', 'doc_id', 'feature_type', 'feature_id', 'expl_id');

			INSERT INTO publi_seed (source_relation, source_sql, target_name, object_type, pk_columns, alias_custom,
				rls_mode, decode_columns, orderby)
			VALUES ('doc_x_feature',
				format('SELECT DISTINCT ON (x.doc_id, x.feature_type, x.feature_id) x.doc_id, x.feature_type, x.feature_id, %s AS expl_id%s FROM (%s) x JOIN %I.doc d ON d.id = x.doc_id %s WHERE x.doc_id IS NOT NULL AND x.feature_id IS NOT NULL',
					CASE WHEN cardinality(v_lateral) > 0 THEN 'f.expl_id' ELSE 'NULL::integer' END,
					COALESCE(', ' || v_doccols, ''),
					array_to_string(v_parts, ' UNION ALL '),
					v_schema,
					CASE WHEN cardinality(v_lateral) > 0
						THEN format('LEFT JOIN LATERAL (%s LIMIT 1) f ON true', array_to_string(v_lateral, ' UNION ALL '))
						ELSE '' END),
				v_prefix || '_doc_x_feature', 'doc', '{doc_id,feature_type,feature_id}', 'Documents linked to objects',
				'expl', false, 61);
		END IF;
	END IF;

	-- EPA results: corporate only
	IF to_regclass(format('%I.rpt_cat_result', v_schema)) IS NOT NULL THEN
		v_where := CASE WHEN EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = format('%I.rpt_cat_result', v_schema)::regclass AND attname = 'iscorporate')
			THEN 'result_id IN (SELECT result_id FROM rpt_cat_result WHERE iscorporate)' END;

		INSERT INTO publi_seed (source_relation, target_name, object_type, pk_columns, where_clause, orderby)
		VALUES ('rpt_cat_result', v_prefix || '_rpt_cat_result', 'result', '{result_id}', v_where, 70);

		FOR v_rec IN
			SELECT * FROM (VALUES ('rpt_arc_stats', 'arc', 'arc_id'), ('rpt_node_stats', 'node', 'node_id')) t(rel, feature, fid)
			WHERE to_regclass(format('%I.%I', v_schema, rel)) IS NOT NULL
		LOOP
			INSERT INTO publi_seed (source_relation, source_sql, target_name, object_type, pk_columns, where_clause, orderby)
			VALUES (v_rec.rel,
				CASE WHEN EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = format('%I.%I', v_schema, v_rec.rel)::regclass AND attname = 'expl_id')
					OR to_regclass(format('%I.%I', v_schema, v_rec.feature)) IS NULL
					THEN NULL
					ELSE format('SELECT s.*, f.expl_id FROM %I.%I s LEFT JOIN %I.%I f ON f.%I::text = s.%I::text',
						v_schema, v_rec.rel, v_schema, v_rec.feature, v_rec.fid, v_rec.fid)
				END,
				v_prefix || '_' || v_rec.rel, 'result', ARRAY['result_id', v_rec.fid], v_where, 71);
		END LOOP;
	END IF;

	-- mincut: header + details, frequent sync
	IF to_regclass(format('%I.om_mincut', v_schema)) IS NOT NULL THEN
		INSERT INTO publi_seed (source_relation, target_name, object_type, pk_columns, sync_frequency, orderby)
		VALUES ('om_mincut', v_prefix || '_om_mincut', 'result', '{id}', 'frequent', 80);

		FOR v_rec IN
			SELECT c.relname::text AS rel
			FROM pg_class c
			WHERE c.relnamespace = to_regnamespace(v_schema) AND c.relkind = 'r'
			AND c.relname IN ('om_mincut_arc', 'om_mincut_node', 'om_mincut_connec', 'om_mincut_hydrometer',
				'om_mincut_valve', 'om_mincut_valve_unaccess', 'om_mincut_polygon')
		LOOP
			INSERT INTO publi_seed (source_relation, source_sql, target_name, object_type, sync_frequency, orderby)
			VALUES (v_rec.rel,
				CASE WHEN EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = format('%I.%I', v_schema, v_rec.rel)::regclass AND attname = 'result_id')
					AND NOT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = format('%I.%I', v_schema, v_rec.rel)::regclass AND attname = 'expl_id')
					THEN format('SELECT x.*, m.expl_id FROM %I.%I x JOIN %I.om_mincut m ON m.id = x.result_id',
						v_schema, v_rec.rel, v_schema)
				END,
				v_prefix || '_' || v_rec.rel, 'result', 'frequent', 81);
		END LOOP;
	END IF;

	IF to_regclass(format('%I.minsector_mincut', v_schema)) IS NOT NULL THEN
		INSERT INTO publi_seed (source_relation, source_sql, target_name, object_type, pk_columns, alias_custom, orderby)
		VALUES ('minsector_mincut',
			CASE WHEN to_regclass(format('%I.minsector', v_schema)) IS NOT NULL
				THEN format('SELECT x.*, m.expl_id FROM %I.minsector_mincut x JOIN %I.minsector m ON m.minsector_id = x.minsector_id',
					v_schema, v_schema)
			END,
			v_prefix || '_minsector_mincut', 'result', '{minsector_id,mincut_minsector_id}',
			'Minsectors affected by cutting a minsector', 90);
	END IF;

	-- resolve pk / rls with a LIMIT 0 probe, then upsert
	PERFORM set_config('search_path', format('%I, public', v_schema), true);

	FOR v_rec IN SELECT * FROM publi_seed ORDER BY orderby, target_name
	LOOP
		v_src := COALESCE(v_rec.source_sql, format('SELECT * FROM %I.%I', v_schema, v_rec.source_relation));
		BEGIN
			DROP TABLE IF EXISTS pg_temp.publi_seed_probe;
			EXECUTE format('CREATE TEMP TABLE publi_seed_probe AS SELECT * FROM (%s) q LIMIT 0', v_src);
		EXCEPTION WHEN OTHERS THEN
			v_skipped := v_skipped || jsonb_build_object('source', v_rec.source_relation, 'reason', SQLERRM);
			CONTINUE;
		END;

		SELECT array_agg(attname::text) INTO v_cols
		FROM pg_attribute
		WHERE attrelid = 'pg_temp.publi_seed_probe'::regclass AND attnum > 0 AND NOT attisdropped;

		v_pk := v_rec.pk_columns;
		IF v_pk IS NULL AND v_rec.object_type = 'epa'
			AND to_regclass(format('%I.%I', v_schema, regexp_replace(v_rec.source_relation, '^ve_', ''))) IS NOT NULL THEN
			SELECT k.cols INTO v_pk
			FROM (
				SELECT con.contype, array_agg(a.attname::text ORDER BY array_position(con.conkey, a.attnum)) AS cols
				FROM pg_constraint con
				JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = ANY (con.conkey)
				WHERE con.conrelid = format('%I.%I', v_schema, regexp_replace(v_rec.source_relation, '^ve_', ''))::regclass
				AND con.contype IN ('p', 'u')
				GROUP BY con.oid, con.contype) k
			WHERE k.cols <@ v_cols
			ORDER BY k.contype = 'p' DESC, cardinality(k.cols)
			LIMIT 1;
		END IF;
		IF v_pk IS NULL AND v_rec.object_type = 'epa' THEN
			-- inp views carry several feature ids (ve_inp_connec has arc_id too): keep the first one unique in the data
			FOR v_col IN
				SELECT c FROM unnest(ARRAY['id', regexp_replace(v_rec.source_relation, '^ve_inp_', '') || '_id',
					'node_id', 'arc_id', 'connec_id', 'gully_id']) WITH ORDINALITY u(c, o)
				WHERE c = ANY (v_cols) ORDER BY o
			LOOP
				EXECUTE format('SELECT count(%1$I) = count(*) AND count(DISTINCT %1$I) = count(*) FROM (%2$s) q', v_col, v_src)
				INTO v_unique;
				IF v_unique THEN
					v_pk := ARRAY[v_col];
					EXIT;
				END IF;
			END LOOP;
		END IF;
		IF v_pk IS NULL AND v_rec.source_sql IS NULL THEN
			SELECT array_agg(a.attname::text ORDER BY array_position(i.indkey::int2[], a.attnum))
			INTO v_pk
			FROM pg_index i
			JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY (i.indkey)
			WHERE i.indrelid = format('%I.%I', v_schema, v_rec.source_relation)::regclass AND i.indisprimary;
		END IF;
		IF v_pk IS NULL AND 'id' = ANY (v_cols) THEN
			v_pk := '{id}';
		END IF;

		IF v_pk IS NULL OR NOT v_pk <@ v_cols THEN
			v_skipped := v_skipped || jsonb_build_object('source', v_rec.source_relation, 'reason', 'no usable primary key');
			CONTINUE;
		END IF;

		v_rls := COALESCE(v_rec.rls_mode, CASE
			WHEN 'expl_id' = ANY (v_cols) THEN 'expl'
			WHEN 'sector_id' = ANY (v_cols) THEN 'sector'
			ELSE 'none' END);

		INSERT INTO publi.config_publi_table (source_schema, source_relation, source_sql, target_name, object_type,
			pk_columns, alias_custom, where_clause, decode_columns, rls_mode, sync_frequency, orderby)
		VALUES (v_schema, v_rec.source_relation, v_rec.source_sql, v_rec.target_name, v_rec.object_type,
			v_pk, v_rec.alias_custom, v_rec.where_clause, v_rec.decode_columns, v_rls, v_rec.sync_frequency, v_rec.orderby)
		ON CONFLICT (target_name) DO NOTHING;
		GET DIAGNOSTICS v_count = ROW_COUNT;

		IF v_count = 0 AND v_replace THEN
			UPDATE publi.config_publi_table SET
				source_schema = v_schema, source_relation = v_rec.source_relation, source_sql = v_rec.source_sql,
				object_type = v_rec.object_type, pk_columns = v_pk, alias_custom = v_rec.alias_custom,
				where_clause = v_rec.where_clause, decode_columns = v_rec.decode_columns, rls_mode = v_rls,
				sync_frequency = v_rec.sync_frequency, orderby = v_rec.orderby
			WHERE target_name = v_rec.target_name;
			GET DIAGNOSTICS v_count = ROW_COUNT;
		END IF;

		IF v_count > 0 THEN
			v_added := v_added || jsonb_build_object('target', v_rec.target_name, 'source', v_rec.source_relation,
				'pk', v_pk, 'rls', v_rls);
		END IF;
	END LOOP;

	DROP TABLE IF EXISTS pg_temp.publi_seed_probe;
	DROP TABLE IF EXISTS pg_temp.publi_seed;

	RETURN json_build_object('status', 'Accepted',
		'body', json_build_object('data', json_build_object(
			'sourceSchema', v_schema,
			'added', v_added,
			'skipped', v_skipped)));

EXCEPTION WHEN OTHERS THEN
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'SQLSTATE', SQLSTATE);
END;
$BODY$
LANGUAGE plpgsql VOLATILE
SET client_min_messages = warning;

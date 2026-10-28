/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- Sample visits and attachments for every CMMS link combination.
-- Not loaded by the cmms manifest: run it after cmms is integrated on a
-- ws/ud schema that already has features. The runner must be able to read
-- those features and write cmms (a superuser is enough; role_cmms cannot
-- select the parent tables).
--
--   psql "$CONN" -v ON_ERROR_STOP=1 -f dbmodel/schemas/addon/cmms/sample/user/sample.sql
--
-- The transaction rolls back if a v_ui_cmms_* check fails.
-- Parents are the latest cmms.sys_version.addparam.parent_schemas.
-- Re-running deletes rows tagged properties.sample = 'cmms_combo' first.
-- ELEMENT is inserted, but tab_cmms is not registered on ve_element.
-- GULLY is skipped when the parent has no gully table (ws).
--
-- Per feature type, on distinct features when the parent has enough rows:
--   visit         1 visit, no attachment
--   visits        2 visits, no attachment (newer link is_last)
--   attach_one    no visit, 1 direct attachment
--   attach_many   no visit, 2 direct attachments (one has a null path)
--   visit_attach  1 visit with 1 attachment, no direct attachment
--   mixed         2 visits (only the first has attachments) and 2 direct
--                 attachments, one of which is also on the first visit
--                 so the attachment view lists that file twice
--   multi_a       private visit, plus the shared links below
--   multi_b       the other end of the same-type share
--
-- Shared, when both multi slots exist for a type:
--   one visit on multi_a and multi_b, with an attachment that is also on
--   multi_a's private visit and direct on multi_b only
--   one direct attachment on both features
--   one attachment on multi_a's private visit and direct on multi_b
--     (the visit is not linked to multi_b)
--
-- Shared across types of one parent (needs 2+ types with that slot):
--   one visit with an attachment on every multi_a
--   one visit with no attachment on every multi_b
--   one direct attachment on every multi_b
--
-- Shared across parents (needs 2+ parents with a multi_a):
--   one visit with an attachment on one multi_a of each parent
--
-- Not linked to any live feature:
--   a visit with nothing
--   two visits that share one attachment
--   an attachment with nothing
--   one link per type whose sys_code matches no feature, with a visit and a
--   direct attachment; v_ui_cmms_* must hide them

BEGIN;

SET LOCAL search_path = cmms, public;

CREATE OR REPLACE FUNCTION pg_temp.cmms_ins_visit(
	p_ext text,
	p_type text,
	p_status text,
	p_title text,
	p_description text,
	p_start timestamptz,
	p_end timestamptz,
	p_geom geometry,
	p_case text
) RETURNS uuid
LANGUAGE plpgsql
SET search_path = cmms, public
AS $fn$
DECLARE
	v_id uuid;
BEGIN
	INSERT INTO cmms.visit (
		ext_visit_id, type, status, title, description,
		start_date, end_date, the_geom, properties, created_by
	) VALUES (
		p_ext, p_type, p_status, p_title, p_description,
		p_start, p_end, p_geom,
		jsonb_build_object('sample', 'cmms_combo', 'case', p_case),
		'cmms_sample'
	)
	RETURNING id INTO v_id;
	RETURN v_id;
END;
$fn$;

CREATE OR REPLACE FUNCTION pg_temp.cmms_ins_attachment(
	p_name text,
	p_case text,
	p_attachment_type text DEFAULT 'photo',
	p_content_type text DEFAULT 'image/jpeg',
	p_path text DEFAULT NULL,
	p_geom geometry DEFAULT NULL,
	p_coordinates jsonb DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql
SET search_path = cmms, public
AS $fn$
DECLARE
	v_id uuid;
	v_path text;
BEGIN
	-- Empty string stores a null path. A null argument gets a placeholder file.
	v_path := CASE
		WHEN p_path = '' THEN NULL
		WHEN p_path IS NULL THEN '/tmp/cmms-sample/' || p_case
		ELSE p_path
	END;
	INSERT INTO cmms.attachment (
		name, code, description, content_type, path, thumbnail_path, size,
		attachment_type, properties, coordinates, the_geom, uploaded_by, metadata
	) VALUES (
		p_name,
		left(p_case, 255),
		p_name,
		p_content_type,
		v_path,
		CASE WHEN p_attachment_type = 'photo' AND v_path IS NOT NULL THEN v_path || '.thumb.jpg' END,
		2048,
		p_attachment_type,
		jsonb_build_object('sample', 'cmms_combo', 'case', p_case),
		p_coordinates,
		p_geom,
		'cmms_sample',
		jsonb_build_object('sample', 'cmms_combo', 'case', p_case)
	)
	RETURNING id INTO v_id;
	RETURN v_id;
END;
$fn$;

CREATE OR REPLACE FUNCTION pg_temp.cmms_link_visit(p_visit uuid, p_sys_code text) RETURNS void
LANGUAGE sql
SET search_path = cmms, public
AS $fn$
	INSERT INTO cmms.visit_x_feature (visit_id, sys_code) VALUES (p_visit, p_sys_code);
$fn$;

CREATE OR REPLACE FUNCTION pg_temp.cmms_link_att_visit(p_att uuid, p_visit uuid) RETURNS void
LANGUAGE sql
SET search_path = cmms, public
AS $fn$
	INSERT INTO cmms.attachment_x_visit (attachment_id, visit_id) VALUES (p_att, p_visit);
$fn$;

CREATE OR REPLACE FUNCTION pg_temp.cmms_link_att_feature(p_att uuid, p_sys_code text) RETURNS void
LANGUAGE sql
SET search_path = cmms, public
AS $fn$
	INSERT INTO cmms.attachment_x_feature (attachment_id, sys_code) VALUES (p_att, p_sys_code);
$fn$;

DO $sample$
DECLARE
	v_parents text[];
	v_parent text;
	v_types text[] := ARRAY['ARC', 'NODE', 'CONNEC', 'LINK', 'GULLY', 'ELEMENT'];
	v_slots text[] := ARRAY[
		'visit', 'visits', 'attach_one', 'attach_many',
		'visit_attach', 'mixed', 'multi_a', 'multi_b'
	];
	v_type text;
	v_slot text;
	v_type_i int;
	v_slot_i int;
	v_srid int;
	v_ids text[];
	v_codes text[];
	v_fid text;
	v_sys_code text;
	v_geom geometry;
	v_has_state boolean;
	v_sql text;
	v_state_sql text;
	v_visit uuid;
	v_visit2 uuid;
	v_att uuid;
	v_primary uuid;
	v_exp_visits int;
	v_exp_atts int;
	v_exp_direct int;
	v_exp_has int;
	v_exp_dup int;
	v_n int;
	v_label text;
	v_links int;
	v_last int;
	v_got_visits int;
	v_got_has int;
	v_got_atts int;
	v_got_direct int;
	v_got_dup int;
	v_base_links int;
	v_failed int := 0;
	v_noview text := '';
	v_idcol text;
	rec record;
BEGIN
	IF to_regclass('cmms.visit') IS NULL THEN
		RAISE EXCEPTION 'schema cmms is not installed';
	END IF;

	SELECT epsg INTO v_srid FROM cmms.sys_version ORDER BY id DESC LIMIT 1;
	SELECT COALESCE(array_agg(DISTINCT elem ORDER BY elem), ARRAY[]::text[])
	INTO v_parents
	FROM cmms.sys_version AS s
	CROSS JOIN LATERAL jsonb_array_elements_text(
		COALESCE(s.addparam -> 'parent_schemas', '[]'::jsonb)
	) AS elem
	WHERE s.id = (SELECT max(id) FROM cmms.sys_version);

	IF cardinality(v_parents) = 0 THEN
		RAISE EXCEPTION 'cmms has no parent_schemas; integrate it onto a ws/ud schema first';
	END IF;

	DELETE FROM cmms.visit WHERE properties ->> 'sample' = 'cmms_combo';
	DELETE FROM cmms.attachment WHERE properties ->> 'sample' = 'cmms_combo';

	CREATE TEMP TABLE cmms_sample_slot (
		schema_name text,
		feature_type text,
		slot text,
		feature_id text,
		sys_code text,
		primary_visit uuid,
		ref_att uuid,
		exp_visits int,
		exp_atts int,
		exp_direct int,
		exp_has int,
		exp_dup int
	) ON COMMIT DROP;

	FOREACH v_parent IN ARRAY v_parents LOOP
		FOR v_type_i IN 1..cardinality(v_types) LOOP
			v_type := v_types[v_type_i];
			v_idcol := lower(v_type) || '_id';

			IF to_regclass(format('%I.%I', v_parent, lower(v_type))) IS NOT NULL THEN
				SELECT EXISTS (
					SELECT 1 FROM information_schema.columns
					WHERE table_schema = v_parent
						AND table_name = lower(v_type)
						AND column_name = 'state'
				) INTO v_has_state;

				v_ids := ARRAY[]::text[];
				v_codes := ARRAY[]::text[];
				IF v_has_state THEN
					v_state_sql := 'AND t.state = 1';
					v_sql := format($pick$
						SELECT COALESCE(array_agg(s.fid ORDER BY s.fid), ARRAY[]::text[]),
							COALESCE(array_agg(s.sys_code ORDER BY s.fid), ARRAY[]::text[])
						FROM (
							SELECT t.%1$I::text AS fid, t.sys_code
							FROM %2$I.%3$I AS t
							WHERE t.sys_code IS NOT NULL
								AND btrim(t.sys_code) <> ''
								AND NOT EXISTS (
									SELECT 1 FROM cmms.visit_x_feature AS vx
									WHERE vx.sys_code = t.sys_code
								)
								AND NOT EXISTS (
									SELECT 1 FROM cmms.attachment_x_feature AS ax
									WHERE ax.sys_code = t.sys_code
								)
								AND NOT EXISTS (
									SELECT 1 FROM cmms_sample_slot AS sl
									WHERE sl.sys_code = t.sys_code
								)
								AND (
									SELECT count(*) FROM %2$I.%3$I AS d
									WHERE d.sys_code = t.sys_code
								) = 1
								%4$s
							ORDER BY t.%1$I
							LIMIT 8
						) AS s
					$pick$, v_idcol, v_parent, lower(v_type), v_state_sql);
					EXECUTE v_sql INTO v_ids, v_codes;
				END IF;

				IF cardinality(v_ids) = 0 THEN
					v_sql := format($pick$
						SELECT COALESCE(array_agg(s.fid ORDER BY s.fid), ARRAY[]::text[]),
							COALESCE(array_agg(s.sys_code ORDER BY s.fid), ARRAY[]::text[])
						FROM (
							SELECT t.%1$I::text AS fid, t.sys_code
							FROM %2$I.%3$I AS t
							WHERE t.sys_code IS NOT NULL
								AND btrim(t.sys_code) <> ''
								AND NOT EXISTS (
									SELECT 1 FROM cmms.visit_x_feature AS vx
									WHERE vx.sys_code = t.sys_code
								)
								AND NOT EXISTS (
									SELECT 1 FROM cmms.attachment_x_feature AS ax
									WHERE ax.sys_code = t.sys_code
								)
								AND NOT EXISTS (
									SELECT 1 FROM cmms_sample_slot AS sl
									WHERE sl.sys_code = t.sys_code
								)
								AND (
									SELECT count(*) FROM %2$I.%3$I AS d
									WHERE d.sys_code = t.sys_code
								) = 1
							ORDER BY t.%1$I
							LIMIT 8
						) AS s
					$pick$, v_idcol, v_parent, lower(v_type));
					EXECUTE v_sql INTO v_ids, v_codes;
				END IF;

				IF cardinality(v_ids) = 0 THEN
					RAISE NOTICE '% %: no features with a unique sys_code, live slots skipped', v_parent, v_type;
				ELSIF cardinality(v_ids) < cardinality(v_slots) THEN
					RAISE NOTICE '% %: % features, slots past that are skipped',
						v_parent, v_type, cardinality(v_ids);
				END IF;

				FOR v_slot_i IN 1..least(cardinality(v_ids), cardinality(v_slots)) LOOP
					v_fid := v_ids[v_slot_i];
					v_sys_code := v_codes[v_slot_i];
					v_slot := v_slots[v_slot_i];
					v_geom := NULL;
					v_primary := NULL;
					v_exp_visits := NULL;
					v_exp_atts := NULL;
					v_exp_direct := NULL;
					v_exp_has := NULL;
					v_exp_dup := NULL;

					IF v_slot IN ('visit', 'attach_one') AND v_srid IS NOT NULL THEN
						BEGIN
							EXECUTE format(
								'SELECT ST_Multi(ST_Force2D(ST_Buffer(ST_Envelope(t.the_geom), 1)))
								 FROM %1$I.%2$I AS t
								 WHERE t.%3$I::text = $1',
								v_parent, lower(v_type), v_idcol
							) INTO v_geom USING v_fid;
							IF v_geom IS NULL
								OR ST_IsEmpty(v_geom)
								OR ST_SRID(v_geom) IS DISTINCT FROM v_srid
								OR GeometryType(v_geom) <> 'MULTIPOLYGON'
							THEN
								v_geom := NULL;
							END IF;
						EXCEPTION WHEN OTHERS THEN
							v_geom := NULL;
						END;
					END IF;

					CASE v_slot
					WHEN 'visit' THEN
						v_primary := pg_temp.cmms_ins_visit(
							format('sample:%s:%s:%s:visit', v_parent, v_type, v_fid),
							'inspection', 'open',
							format('%s %s %s — one visit', v_parent, v_type, v_fid),
							'Visits: 1 row, has_attachment false. Attachments: empty.',
							now() - interval '3 days', NULL, v_geom, 'visit'
						);
						PERFORM pg_temp.cmms_link_visit(v_primary, v_sys_code);
						v_exp_visits := 1;
						v_exp_atts := 0;
						v_exp_direct := 0;
						v_exp_has := 0;
					WHEN 'visits' THEN
						v_primary := pg_temp.cmms_ins_visit(
							format('sample:%s:%s:%s:visits-old', v_parent, v_type, v_fid),
							'survey', 'planned',
							format('%s %s %s — two visits (older)', v_parent, v_type, v_fid),
							'Visits: 2 rows, both has_attachment false. The newer link is_last.',
							now() - interval '20 days', NULL, NULL, 'visits'
						);
						PERFORM pg_temp.cmms_link_visit(v_primary, v_sys_code);
						v_visit2 := pg_temp.cmms_ins_visit(
							NULL,
							'repair', 'closed',
							format('%s %s %s — two visits (newer)', v_parent, v_type, v_fid),
							'No ext_visit_id. end_date equals start_date.',
							now() - interval '1 day', now() - interval '1 day', NULL, 'visits'
						);
						PERFORM pg_temp.cmms_link_visit(v_visit2, v_sys_code);
						v_exp_visits := 2;
						v_exp_atts := 0;
						v_exp_direct := 0;
						v_exp_has := 0;
					WHEN 'attach_one' THEN
						v_att := pg_temp.cmms_ins_attachment(
							format('%s %s %s photo', v_parent, v_type, v_fid),
							format('%s-%s-%s-one', v_parent, v_type, v_fid),
							'photo', 'image/jpeg', NULL, v_geom,
							'{"lat": 41.387, "lon": 2.170}'::jsonb
						);
						PERFORM pg_temp.cmms_link_att_feature(v_att, v_sys_code);
						v_exp_visits := 0;
						v_exp_atts := 1;
						v_exp_direct := 1;
					WHEN 'attach_many' THEN
						PERFORM pg_temp.cmms_link_att_feature(pg_temp.cmms_ins_attachment(
							format('%s %s %s photo', v_parent, v_type, v_fid),
							format('%s-%s-%s-many-1', v_parent, v_type, v_fid)
						), v_sys_code);
						PERFORM pg_temp.cmms_link_att_feature(pg_temp.cmms_ins_attachment(
							format('%s %s %s document, no path', v_parent, v_type, v_fid),
							format('%s-%s-%s-many-2', v_parent, v_type, v_fid),
							'document', 'application/pdf', ''
						), v_sys_code);
						v_exp_visits := 0;
						v_exp_atts := 2;
						v_exp_direct := 2;
					WHEN 'visit_attach' THEN
						v_primary := pg_temp.cmms_ins_visit(
							format('sample:%s:%s:%s:with-att', v_parent, v_type, v_fid),
							'cleaning', 'closed',
							format('%s %s %s — visit with attachment', v_parent, v_type, v_fid),
							'Visits: 1 row, has_attachment true. Attachments: 1 row with that visit_id.',
							now() - interval '4 days', now() - interval '4 days' + interval '2 hours',
							NULL, 'visit_attach'
						);
						PERFORM pg_temp.cmms_link_visit(v_primary, v_sys_code);
						PERFORM pg_temp.cmms_link_att_visit(pg_temp.cmms_ins_attachment(
							format('%s %s %s visit photo', v_parent, v_type, v_fid),
							format('%s-%s-%s-via-visit', v_parent, v_type, v_fid)
						), v_primary);
						v_exp_visits := 1;
						v_exp_atts := 1;
						v_exp_direct := 0;
						v_exp_has := 1;
					WHEN 'mixed' THEN
						v_primary := pg_temp.cmms_ins_visit(
							format('sample:%s:%s:%s:mixed', v_parent, v_type, v_fid),
							'leak', 'open',
							format('%s %s %s — mixed (with attachments)', v_parent, v_type, v_fid),
							'Two visits, only this one has attachments. One file is both direct and on this visit, so it is listed twice.',
							now() - interval '6 days', NULL, NULL, 'mixed'
						);
						PERFORM pg_temp.cmms_link_visit(v_primary, v_sys_code);
						v_att := pg_temp.cmms_ins_attachment(
							format('%s %s %s mixed A1', v_parent, v_type, v_fid),
							format('%s-%s-%s-mixed-a1', v_parent, v_type, v_fid)
						);
						PERFORM pg_temp.cmms_link_att_visit(v_att, v_primary);
						v_att := pg_temp.cmms_ins_attachment(
							format('%s %s %s mixed A2', v_parent, v_type, v_fid),
							format('%s-%s-%s-mixed-a2', v_parent, v_type, v_fid),
							'video', 'video/mp4',
							format('/tmp/cmms-sample/%s-%s-%s-mixed-a2.mp4', v_parent, v_type, v_fid)
						);
						PERFORM pg_temp.cmms_link_att_visit(v_att, v_primary);
						v_visit2 := pg_temp.cmms_ins_visit(
							format('sample:%s:%s:%s:mixed-bare', v_parent, v_type, v_fid),
							'incident', 'planned',
							format('%s %s %s — mixed (no attachment)', v_parent, v_type, v_fid),
							'Second visit on the same feature. has_attachment false.',
							NULL, NULL, NULL, 'mixed'
						);
						PERFORM pg_temp.cmms_link_visit(v_visit2, v_sys_code);
						PERFORM pg_temp.cmms_link_att_feature(pg_temp.cmms_ins_attachment(
							format('%s %s %s mixed direct', v_parent, v_type, v_fid),
							format('%s-%s-%s-mixed-direct', v_parent, v_type, v_fid),
							'document', 'application/pdf',
							format('/tmp/cmms-sample/%s-%s-%s-mixed-direct.pdf', v_parent, v_type, v_fid)
						), v_sys_code);
						v_att := pg_temp.cmms_ins_attachment(
							format('%s %s %s mixed both ways', v_parent, v_type, v_fid),
							format('%s-%s-%s-mixed-both', v_parent, v_type, v_fid)
						);
						PERFORM pg_temp.cmms_link_att_feature(v_att, v_sys_code);
						PERFORM pg_temp.cmms_link_att_visit(v_att, v_primary);
						v_exp_visits := 2;
						v_exp_atts := 5;
						v_exp_direct := 2;
						v_exp_has := 1;
						v_exp_dup := 1;
					WHEN 'multi_a' THEN
						v_primary := pg_temp.cmms_ins_visit(
							format('sample:%s:%s:%s:private', v_parent, v_type, v_fid),
							'inspection', 'open',
							format('%s %s %s — multi A private visit', v_parent, v_type, v_fid),
							'Also receives the same-type and cross-type shared visits when those slots exist.',
							now() - interval '2 days', NULL, NULL, 'multi_a'
						);
						PERFORM pg_temp.cmms_link_visit(v_primary, v_sys_code);
					WHEN 'multi_b' THEN
						v_primary := NULL;
					ELSE
						RAISE EXCEPTION 'unknown slot %', v_slot;
					END CASE;

					RAISE NOTICE '% % %  %', v_parent, v_type, v_fid, v_slot;

					INSERT INTO cmms_sample_slot (
						schema_name, feature_type, slot, feature_id, sys_code, primary_visit,
						exp_visits, exp_atts, exp_direct, exp_has, exp_dup
					) VALUES (
						v_parent, v_type, v_slot, v_fid, v_sys_code, v_primary,
						v_exp_visits, v_exp_atts, v_exp_direct, v_exp_has, v_exp_dup
					);
				END LOOP;
			ELSE
				RAISE NOTICE '% %: table does not exist, live slots skipped', v_parent, v_type;
			END IF;

			-- sys_code matches no feature. The link stays in cmms and must not show.
			v_sys_code := format('sample:%s:%s:orphan', v_parent, v_type);
			v_visit := pg_temp.cmms_ins_visit(
				format('sample:%s:%s:orphan', v_parent, v_type),
				'inspection', 'cancelled',
				format('%s %s — orphan visit (hidden)', v_parent, v_type),
				'Linked by a sys_code that matches no feature. Must not appear in v_ui_cmms_visit.',
				now(), NULL, NULL, 'orphan'
			);
			PERFORM pg_temp.cmms_link_visit(v_visit, v_sys_code);
			PERFORM pg_temp.cmms_link_att_visit(pg_temp.cmms_ins_attachment(
				format('%s %s orphan via visit', v_parent, v_type),
				format('%s-%s-orphan-visit', v_parent, v_type)
			), v_visit);
			PERFORM pg_temp.cmms_link_att_feature(pg_temp.cmms_ins_attachment(
				format('%s %s orphan direct', v_parent, v_type),
				format('%s-%s-orphan-direct', v_parent, v_type),
				'document', 'application/pdf', ''
			), v_sys_code);

			INSERT INTO cmms_sample_slot (
				schema_name, feature_type, slot, feature_id, sys_code, primary_visit,
				exp_visits, exp_atts, exp_direct
			) VALUES (
				v_parent, v_type, 'orphan', NULL, v_sys_code, v_visit, 0, 0, 0
			);
		END LOOP;

		-- One visit on two features of this type.
		FOR rec IN
			SELECT a.feature_type, a.feature_id AS fid_a, a.sys_code AS code_a, a.primary_visit,
				b.feature_id AS fid_b, b.sys_code AS code_b
			FROM cmms_sample_slot AS a
			JOIN cmms_sample_slot AS b
				ON b.schema_name = a.schema_name
				AND b.feature_type = a.feature_type
				AND b.slot = 'multi_b'
			WHERE a.schema_name = v_parent
				AND a.slot = 'multi_a'
		LOOP
			v_visit := pg_temp.cmms_ins_visit(
				format('sample:%s:%s:pair', v_parent, rec.feature_type),
				'inspection', 'open',
				format('%s %s %s + %s — one visit, two features', v_parent, rec.feature_type, rec.fid_a, rec.fid_b),
				'Same visit on multi A and multi B. Its attachment is also on multi A private visit and direct on multi B only.',
				now() - interval '2 days', NULL, NULL, 'pair'
			);
			PERFORM pg_temp.cmms_link_visit(v_visit, rec.code_a);
			PERFORM pg_temp.cmms_link_visit(v_visit, rec.code_b);
			v_att := pg_temp.cmms_ins_attachment(
				format('%s %s shared by two visits', v_parent, rec.feature_type),
				format('%s-%s-pair', v_parent, rec.feature_type)
			);
			PERFORM pg_temp.cmms_link_att_visit(v_att, v_visit);
			PERFORM pg_temp.cmms_link_att_visit(v_att, rec.primary_visit);
			PERFORM pg_temp.cmms_link_att_feature(v_att, rec.code_b);

			v_att := pg_temp.cmms_ins_attachment(
				format('%s %s direct on both features', v_parent, rec.feature_type),
				format('%s-%s-both', v_parent, rec.feature_type),
				'document', 'application/pdf',
				format('/tmp/cmms-sample/%s-%s-both.pdf', v_parent, rec.feature_type)
			);
			PERFORM pg_temp.cmms_link_att_feature(v_att, rec.code_a);
			PERFORM pg_temp.cmms_link_att_feature(v_att, rec.code_b);

			v_att := pg_temp.cmms_ins_attachment(
				format('%s %s visit on A, direct on B', v_parent, rec.feature_type),
				format('%s-%s-split', v_parent, rec.feature_type)
			);
			PERFORM pg_temp.cmms_link_att_visit(v_att, rec.primary_visit);
			PERFORM pg_temp.cmms_link_att_feature(v_att, rec.code_b);
			RAISE NOTICE '% % pair % + %', v_parent, rec.feature_type, rec.fid_a, rec.fid_b;
		END LOOP;

		SELECT count(*) INTO v_n
		FROM cmms_sample_slot
		WHERE schema_name = v_parent AND slot = 'multi_a';
		IF v_n >= 2 THEN
			SELECT string_agg(format('%s %s', feature_type, feature_id), ', ' ORDER BY feature_type)
			INTO v_label
			FROM cmms_sample_slot
			WHERE schema_name = v_parent AND slot = 'multi_a';
			v_visit := pg_temp.cmms_ins_visit(
				format('sample:%s:cross', v_parent),
				'survey', 'closed',
				format('%s cross-type visit — %s', v_parent, v_label),
				'One visit, and its attachment, on multi A of every type that had enough features.',
				now() - interval '5 days', now() - interval '5 days' + interval '1 hour', NULL, 'cross'
			);
			v_att := pg_temp.cmms_ins_attachment(
				format('%s cross-type visit photo', v_parent),
				format('%s-cross', v_parent)
			);
			PERFORM pg_temp.cmms_link_att_visit(v_att, v_visit);
			FOR rec IN
				SELECT sys_code FROM cmms_sample_slot
				WHERE schema_name = v_parent AND slot = 'multi_a'
			LOOP
				PERFORM pg_temp.cmms_link_visit(v_visit, rec.sys_code);
			END LOOP;
			RAISE NOTICE '% cross-type visit on % multi A features', v_parent, v_n;
		END IF;

		SELECT count(*) INTO v_n
		FROM cmms_sample_slot
		WHERE schema_name = v_parent AND slot = 'multi_b';
		IF v_n >= 2 THEN
			SELECT string_agg(format('%s %s', feature_type, feature_id), ', ' ORDER BY feature_type)
			INTO v_label
			FROM cmms_sample_slot
			WHERE schema_name = v_parent AND slot = 'multi_b';
			v_visit := pg_temp.cmms_ins_visit(
				NULL,
				'repair', 'open',
				format('%s cross-type visit, no attachment — %s', v_parent, v_label),
				'One visit on multi B of every type. No ext_visit_id and no attachment.',
				now() - interval '1 day', NULL, NULL, 'cross_bare'
			);
			FOR rec IN
				SELECT sys_code FROM cmms_sample_slot
				WHERE schema_name = v_parent AND slot = 'multi_b'
			LOOP
				PERFORM pg_temp.cmms_link_visit(v_visit, rec.sys_code);
			END LOOP;
			v_att := pg_temp.cmms_ins_attachment(
				format('%s cross-type direct', v_parent),
				format('%s-cross-direct', v_parent),
				'document', 'application/pdf',
				format('/tmp/cmms-sample/%s-cross-direct.pdf', v_parent)
			);
			FOR rec IN
				SELECT sys_code FROM cmms_sample_slot
				WHERE schema_name = v_parent AND slot = 'multi_b'
			LOOP
				PERFORM pg_temp.cmms_link_att_feature(v_att, rec.sys_code);
			END LOOP;
			RAISE NOTICE '% cross-type bare visit and direct attachment on % multi B features', v_parent, v_n;
		END IF;
	END LOOP;

	SELECT count(DISTINCT schema_name) INTO v_n
	FROM cmms_sample_slot
	WHERE slot = 'multi_a';
	IF v_n >= 2 THEN
		v_visit := pg_temp.cmms_ins_visit(
			'sample:cross-parent',
			'inspection', 'open',
			'cross-parent visit',
			'One visit and its attachment on one multi A feature of each parent schema.',
			now() - interval '8 days', NULL, NULL, 'cross_parent'
		);
		v_att := pg_temp.cmms_ins_attachment(
			'cross-parent photo',
			'cross-parent'
		);
		PERFORM pg_temp.cmms_link_att_visit(v_att, v_visit);
		FOR rec IN
			SELECT DISTINCT ON (schema_name) schema_name, feature_type, feature_id, sys_code
			FROM cmms_sample_slot
			WHERE slot = 'multi_a'
			ORDER BY schema_name, CASE feature_type WHEN 'NODE' THEN 0 ELSE 1 END, feature_type
		LOOP
			PERFORM pg_temp.cmms_link_visit(v_visit, rec.sys_code);
			RAISE NOTICE 'cross-parent visit also on % % %', rec.schema_name, rec.feature_type, rec.feature_id;
		END LOOP;
	END IF;

	v_visit := pg_temp.cmms_ins_visit(
		'sample:unlinked',
		'inspection', 'cancelled',
		'unlinked visit',
		'No feature and no attachment.',
		NULL, NULL, NULL, 'unlinked'
	);
	INSERT INTO cmms_sample_slot (slot, primary_visit) VALUES ('unlinked', v_visit);

	v_visit := pg_temp.cmms_ins_visit(
		'sample:unlinked-with-attachment',
		'repair', 'open',
		'unlinked visit with attachment',
		'No feature. Shares its attachment with the other unlinked visit.',
		now() - interval '1 day', NULL, NULL, 'unlinked'
	);
	v_visit2 := pg_temp.cmms_ins_visit(
		NULL,
		'survey', 'closed',
		'second unlinked visit, same attachment',
		'No feature and no ext_visit_id. Same attachment as the other unlinked visit.',
		now() - interval '9 days', now() - interval '8 days', NULL, 'unlinked'
	);
	v_att := pg_temp.cmms_ins_attachment(
		'attachment on two unlinked visits',
		'unlinked-shared'
	);
	PERFORM pg_temp.cmms_link_att_visit(v_att, v_visit);
	PERFORM pg_temp.cmms_link_att_visit(v_att, v_visit2);
	INSERT INTO cmms_sample_slot (slot, primary_visit) VALUES ('unlinked', v_visit);
	INSERT INTO cmms_sample_slot (slot, primary_visit) VALUES ('unlinked', v_visit2);
	INSERT INTO cmms_sample_slot (slot, ref_att) VALUES ('unlinked_att', v_att);

	v_att := pg_temp.cmms_ins_attachment(
		'unlinked attachment',
		'unlinked-attachment',
		'document', 'application/pdf', ''
	);
	INSERT INTO cmms_sample_slot (slot, ref_att) VALUES ('unlinked_att', v_att);

	-- is_last: exactly one true link per sample-owned sys_code / visit.
	UPDATE cmms.visit_x_feature AS vx
	SET is_last = (vx.id = sub.max_id)
	FROM (
		SELECT vx2.sys_code, max(vx2.id) AS max_id
		FROM cmms.visit_x_feature AS vx2
		JOIN cmms.visit AS v ON v.id = vx2.visit_id
		WHERE v.properties ->> 'sample' = 'cmms_combo'
		GROUP BY vx2.sys_code
	) AS sub
	WHERE vx.sys_code = sub.sys_code
		AND vx.visit_id IN (
			SELECT id FROM cmms.visit WHERE properties ->> 'sample' = 'cmms_combo'
		);

	UPDATE cmms.attachment_x_feature AS ax
	SET is_last = (ax.id = sub.max_id)
	FROM (
		SELECT ax2.sys_code, max(ax2.id) AS max_id
		FROM cmms.attachment_x_feature AS ax2
		JOIN cmms.attachment AS a ON a.id = ax2.attachment_id
		WHERE a.properties ->> 'sample' = 'cmms_combo'
		GROUP BY ax2.sys_code
	) AS sub
	WHERE ax.sys_code = sub.sys_code
		AND ax.attachment_id IN (
			SELECT id FROM cmms.attachment WHERE properties ->> 'sample' = 'cmms_combo'
		);

	UPDATE cmms.attachment_x_visit AS ax
	SET is_last = (ax.id = sub.max_id)
	FROM (
		SELECT ax2.visit_id, max(ax2.id) AS max_id
		FROM cmms.attachment_x_visit AS ax2
		JOIN cmms.visit AS v ON v.id = ax2.visit_id
		WHERE v.properties ->> 'sample' = 'cmms_combo'
		GROUP BY ax2.visit_id
	) AS sub
	WHERE ax.visit_id = sub.visit_id;

	FOR rec IN
		SELECT DISTINCT s.sys_code
		FROM (
			SELECT vx.sys_code
			FROM cmms.visit_x_feature AS vx
			JOIN cmms.visit AS v ON v.id = vx.visit_id
			WHERE v.properties ->> 'sample' = 'cmms_combo'
			UNION
			SELECT ax.sys_code
			FROM cmms.attachment_x_feature AS ax
			JOIN cmms.attachment AS a ON a.id = ax.attachment_id
			WHERE a.properties ->> 'sample' = 'cmms_combo'
		) AS s
	LOOP
		SELECT count(*)::int, count(*) FILTER (WHERE vx.is_last)::int
		INTO v_links, v_last
		FROM cmms.visit_x_feature AS vx
		JOIN cmms.visit AS v ON v.id = vx.visit_id
		WHERE vx.sys_code = rec.sys_code
			AND v.properties ->> 'sample' = 'cmms_combo';
		IF v_links > 0 AND v_last IS DISTINCT FROM 1 THEN
			v_failed := v_failed + 1;
			RAISE WARNING 'sys_code % visit is_last count is %, expected 1 of %', rec.sys_code, v_last, v_links;
		END IF;

		SELECT count(*)::int, count(*) FILTER (WHERE ax.is_last)::int
		INTO v_links, v_last
		FROM cmms.attachment_x_feature AS ax
		JOIN cmms.attachment AS a ON a.id = ax.attachment_id
		WHERE ax.sys_code = rec.sys_code
			AND a.properties ->> 'sample' = 'cmms_combo';
		IF v_links > 0 AND v_last IS DISTINCT FROM 1 THEN
			v_failed := v_failed + 1;
			RAISE WARNING 'sys_code % attachment is_last count is %, expected 1 of %', rec.sys_code, v_last, v_links;
		END IF;
	END LOOP;

	FOR rec IN
		SELECT id, title FROM cmms.visit WHERE properties ->> 'sample' = 'cmms_combo'
	LOOP
		SELECT count(*)::int, count(*) FILTER (WHERE is_last)::int
		INTO v_links, v_last
		FROM cmms.attachment_x_visit
		WHERE visit_id = rec.id;
		IF v_links > 0 AND v_last IS DISTINCT FROM 1 THEN
			v_failed := v_failed + 1;
			RAISE WARNING 'visit % attachment is_last count is %, expected 1 of %', rec.title, v_last, v_links;
		END IF;
	END LOOP;

	FOR rec IN
		SELECT * FROM cmms_sample_slot WHERE exp_visits IS NOT NULL AND schema_name IS NOT NULL
	LOOP
		IF to_regclass(format('%I.v_ui_cmms_visit', rec.schema_name)) IS NULL THEN
			IF v_noview IS DISTINCT FROM rec.schema_name THEN
				RAISE NOTICE '% has no v_ui_cmms_visit, skip view checks', rec.schema_name;
				v_noview := rec.schema_name;
			END IF;
			CONTINUE;
		END IF;
		BEGIN
			EXECUTE format(
				'SELECT count(*)::int, count(*) FILTER (WHERE has_attachment)::int
				 FROM %I.v_ui_cmms_visit
				 WHERE feature_id = $1 AND feature_type = $2',
				rec.schema_name
			) INTO v_got_visits, v_got_has USING rec.feature_id, rec.feature_type;
			EXECUTE format(
				'SELECT count(*)::int, count(*) FILTER (WHERE visit_id IS NULL)::int
				 FROM %I.v_ui_cmms_attachment
				 WHERE feature_id = $1 AND feature_type = $2',
				rec.schema_name
			) INTO v_got_atts, v_got_direct USING rec.feature_id, rec.feature_type;

			IF v_got_visits IS DISTINCT FROM rec.exp_visits
				OR v_got_atts IS DISTINCT FROM rec.exp_atts
				OR v_got_direct IS DISTINCT FROM rec.exp_direct
				OR (rec.exp_has IS NOT NULL AND rec.exp_visits > 0 AND v_got_has IS DISTINCT FROM rec.exp_has)
			THEN
				v_failed := v_failed + 1;
				RAISE WARNING '% % % slot=% visits %/% attachments %/% direct %/% has_attachment %/%',
					rec.schema_name, rec.feature_type, rec.feature_id, rec.slot,
					v_got_visits, rec.exp_visits, v_got_atts, rec.exp_atts,
					v_got_direct, rec.exp_direct, v_got_has, rec.exp_has;
			END IF;

			IF rec.exp_dup IS NOT NULL THEN
				EXECUTE format(
					'SELECT count(*)::int FROM (
						SELECT attachment_id
						FROM %I.v_ui_cmms_attachment
						WHERE feature_id = $1 AND feature_type = $2
						GROUP BY attachment_id
						HAVING count(*) > 1
					) AS d',
					rec.schema_name
				) INTO v_got_dup USING rec.feature_id, rec.feature_type;
				IF v_got_dup < rec.exp_dup THEN
					v_failed := v_failed + 1;
					RAISE WARNING '% % % slot=% expected an attachment listed more than once',
						rec.schema_name, rec.feature_type, rec.feature_id, rec.slot;
				END IF;
			END IF;

			IF rec.slot = 'orphan' THEN
				SELECT count(*)::int INTO v_base_links
				FROM cmms.visit_x_feature
				WHERE sys_code = rec.sys_code;
				IF v_base_links IS DISTINCT FROM 1 THEN
					v_failed := v_failed + 1;
					RAISE WARNING 'orphan % lost its visit link', rec.sys_code;
				END IF;
				EXECUTE format(
					'SELECT count(*)::int FROM %I.v_ui_cmms_visit WHERE visit_id = $1',
					rec.schema_name
				) INTO v_got_visits USING rec.primary_visit;
				IF v_got_visits <> 0 THEN
					v_failed := v_failed + 1;
					RAISE WARNING 'orphan visit % is visible on %', rec.primary_visit, rec.schema_name;
				END IF;
			END IF;
		EXCEPTION WHEN OTHERS THEN
			v_failed := v_failed + 1;
			RAISE WARNING 'view check failed for % % %: %',
				rec.schema_name, rec.feature_type, rec.slot, SQLERRM;
		END;
	END LOOP;

	FOR rec IN SELECT primary_visit, ref_att, slot FROM cmms_sample_slot WHERE slot IN ('unlinked', 'unlinked_att') LOOP
		FOREACH v_parent IN ARRAY v_parents LOOP
			IF to_regclass(format('%I.v_ui_cmms_visit', v_parent)) IS NULL THEN
				CONTINUE;
			END IF;
			BEGIN
				IF rec.slot = 'unlinked' THEN
					EXECUTE format(
						'SELECT count(*)::int FROM %I.v_ui_cmms_visit WHERE visit_id = $1',
						v_parent
					) INTO v_got_visits USING rec.primary_visit;
					IF v_got_visits <> 0 THEN
						v_failed := v_failed + 1;
						RAISE WARNING 'unlinked visit % is visible on %', rec.primary_visit, v_parent;
					END IF;
				ELSE
					EXECUTE format(
						'SELECT count(*)::int FROM %I.v_ui_cmms_attachment WHERE attachment_id = $1',
						v_parent
					) INTO v_got_atts USING rec.ref_att;
					IF v_got_atts <> 0 THEN
						v_failed := v_failed + 1;
						RAISE WARNING 'unlinked attachment % is visible on %', rec.ref_att, v_parent;
					END IF;
				END IF;
			EXCEPTION WHEN OTHERS THEN
				v_failed := v_failed + 1;
				RAISE WARNING 'unlinked check failed on %: %', v_parent, SQLERRM;
			END;
		END LOOP;
	END LOOP;

	IF v_failed > 0 THEN
		RAISE EXCEPTION '% cmms sample checks failed', v_failed;
	END IF;

	RAISE NOTICE 'cmms sample checks passed';
	RAISE NOTICE 'visits %  attachments %  feature links %',
		(SELECT count(*) FROM cmms.visit WHERE properties ->> 'sample' = 'cmms_combo'),
		(SELECT count(*) FROM cmms.attachment WHERE properties ->> 'sample' = 'cmms_combo'),
		(SELECT count(*) FROM cmms.visit_x_feature AS vx
			JOIN cmms.visit AS v ON v.id = vx.visit_id
			WHERE v.properties ->> 'sample' = 'cmms_combo');
END;
$sample$;

SELECT v.title, v.type, v.status,
	v.ext_visit_id IS NOT NULL AS has_ext_id,
	v.the_geom IS NOT NULL AS has_geom,
	(SELECT count(*) FROM cmms.visit_x_feature AS x WHERE x.visit_id = v.id) AS features,
	(SELECT count(*) FROM cmms.attachment_x_visit AS x WHERE x.visit_id = v.id) AS attachments
FROM cmms.visit AS v
WHERE v.properties ->> 'sample' = 'cmms_combo'
ORDER BY v.title;

SELECT a.name, a.attachment_type,
	a.path IS NOT NULL AS has_path,
	a.the_geom IS NOT NULL AS has_geom,
	(SELECT count(*) FROM cmms.attachment_x_feature AS x WHERE x.attachment_id = a.id) AS features,
	(SELECT count(*) FROM cmms.attachment_x_visit AS x WHERE x.attachment_id = a.id) AS visits
FROM cmms.attachment AS a
WHERE a.properties ->> 'sample' = 'cmms_combo'
ORDER BY a.name;

SELECT s.schema_name, s.feature_type, s.feature_id, s.slot, s.sys_code,
	s.feature_id IS NULL AS unmatched,
	(SELECT count(*) FROM cmms.visit_x_feature AS v WHERE v.sys_code = s.sys_code) AS visits,
	(SELECT count(*) FROM cmms.attachment_x_feature AS a WHERE a.sys_code = s.sys_code) AS direct_attachments
FROM cmms_sample_slot AS s
WHERE s.schema_name IS NOT NULL
ORDER BY s.schema_name, s.feature_type, unmatched, s.feature_id;

DO $drop$
DECLARE
	r record;
BEGIN
	FOR r IN
		SELECT p.oid::regprocedure::text AS sig
		FROM pg_proc AS p
		JOIN pg_namespace AS n ON n.oid = p.pronamespace
		WHERE n.nspname LIKE 'pg_temp%'
			AND p.proname IN (
				'cmms_ins_visit', 'cmms_ins_attachment',
				'cmms_link_visit', 'cmms_link_att_visit', 'cmms_link_att_feature'
			)
	LOOP
		EXECUTE format('DROP FUNCTION %s', r.sig);
	END LOOP;
END;
$drop$;

COMMIT;

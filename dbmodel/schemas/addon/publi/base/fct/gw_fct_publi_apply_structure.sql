/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION publi.gw_fct_publi_apply_structure(p_data json)
RETURNS json AS
$BODY$

/*example
SELECT publi.gw_fct_publi_apply_structure($${"data":{"configId":1, "staging":"publi_stg_1"}}$$);

Internal step of gw_fct_publi_sync: raises on error.
Returns mode:
  create  live table did not exist, created from staging (data already loaded)
  swap    columns could not be altered or pk changed, table recreated from staging (data already loaded)
  alter   columns added / dropped / retyped in place, data still to apply
  none    same columns, data still to apply
The caller must run gw_fct_publi_apply_security after create / swap: a new table has no pk, index, grant or policy.
*/

DECLARE
	v_cfg publi.config_publi_table;
	v_stg text;
	v_live regclass;
	v_rec record;
	v_mode text := 'none';
	v_swap boolean := false;
	v_reason text;
	v_livepk text[];
	v_added jsonb := '[]';
	v_dropped jsonb := '[]';
	v_retyped jsonb := '[]';
BEGIN
	SELECT * INTO v_cfg FROM publi.config_publi_table WHERE id = (p_data -> 'data' ->> 'configId')::int;
	IF v_cfg.id IS NULL THEN
		RAISE EXCEPTION 'config_publi_table id % not found', p_data -> 'data' ->> 'configId';
	END IF;

	v_stg := p_data -> 'data' ->> 'staging';
	IF to_regclass(format('pg_temp.%I', v_stg)) IS NULL THEN
		RAISE EXCEPTION 'staging table % not found', v_stg;
	END IF;

	v_live := to_regclass(format('publi.%I', v_cfg.target_name));

	IF v_live IS NULL THEN
		EXECUTE format('CREATE TABLE publi.%I AS SELECT * FROM pg_temp.%I', v_cfg.target_name, v_stg);
		RETURN json_build_object('status', 'Accepted',
			'body', json_build_object('data', json_build_object('mode', 'create')));
	END IF;

	SELECT array_agg(a.attname::text ORDER BY array_position(i.indkey::int2[], a.attnum))
	INTO v_livepk
	FROM pg_index i
	JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY (i.indkey)
	WHERE i.indrelid = v_live AND i.indisprimary;

	IF v_livepk IS NOT NULL AND v_livepk IS DISTINCT FROM v_cfg.pk_columns THEN
		v_swap := true;
		v_reason := format('pk changed from %s to %s', v_livepk, v_cfg.pk_columns);
	END IF;

	IF NOT v_swap THEN
		FOR v_rec IN
			WITH s AS (
				SELECT attname::text AS col, format_type(atttypid, atttypmod) AS typ
				FROM pg_attribute
				WHERE attrelid = format('pg_temp.%I', v_stg)::regclass AND attnum > 0 AND NOT attisdropped
			), l AS (
				SELECT attname::text AS col, format_type(atttypid, atttypmod) AS typ
				FROM pg_attribute
				WHERE attrelid = v_live AND attnum > 0 AND NOT attisdropped
			)
			SELECT COALESCE(s.col, l.col) AS col, s.typ AS new_type,
				CASE WHEN l.col IS NULL THEN 'ADD' WHEN s.col IS NULL THEN 'DROP' ELSE 'TYPE' END AS action
			FROM s FULL JOIN l USING (col)
			WHERE s.typ IS DISTINCT FROM l.typ
			ORDER BY 3, 1
		LOOP
			IF v_rec.col = ANY (v_cfg.pk_columns) THEN
				v_swap := true;
				v_reason := format('pk column %s changed (%s)', v_rec.col, v_rec.action);
				EXIT;
			END IF;

			BEGIN
				IF v_rec.action = 'ADD' THEN
					EXECUTE format('ALTER TABLE publi.%I ADD COLUMN %I %s', v_cfg.target_name, v_rec.col, v_rec.new_type);
					v_added := v_added || to_jsonb(v_rec.col);
				ELSIF v_rec.action = 'DROP' THEN
					EXECUTE format('ALTER TABLE publi.%I DROP COLUMN %I', v_cfg.target_name, v_rec.col);
					v_dropped := v_dropped || to_jsonb(v_rec.col);
				ELSE
					EXECUTE format('ALTER TABLE publi.%I ALTER COLUMN %I TYPE %s USING %I::%s',
						v_cfg.target_name, v_rec.col, v_rec.new_type, v_rec.col, v_rec.new_type);
					v_retyped := v_retyped || to_jsonb(v_rec.col);
				END IF;
				v_mode := 'alter';
			EXCEPTION WHEN OTHERS THEN
				v_swap := true;
				v_reason := format('%s %s failed: %s', v_rec.action, v_rec.col, SQLERRM);
				EXIT;
			END;
		END LOOP;
	END IF;

	IF v_swap THEN
		EXECUTE format('DROP TABLE publi.%I', v_cfg.target_name);
		EXECUTE format('CREATE TABLE publi.%I AS SELECT * FROM pg_temp.%I', v_cfg.target_name, v_stg);
		v_mode := 'swap';
	END IF;

	RETURN json_build_object('status', 'Accepted',
		'body', json_build_object('data', json_build_object(
			'mode', v_mode,
			'reason', v_reason,
			'added', v_added,
			'dropped', v_dropped,
			'retyped', v_retyped)));
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

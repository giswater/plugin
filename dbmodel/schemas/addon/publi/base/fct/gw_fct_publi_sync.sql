/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION publi.gw_fct_publi_sync(p_data json)
RETURNS json AS
$BODY$

/*example
-- everything active
SELECT publi.gw_fct_publi_sync($${"data":{}}$$);

-- one source schema, only some tables, explicit states / psectors / dscenarios
SELECT publi.gw_fct_publi_sync($${"data":{"sourceSchema":"ws", "targets":["ws_arc","ws_node"],
  "frequency":"daily", "resetSelectors":true, "states":[1], "psectors":[], "dscenarios":[]}}$$);

Run it as the dedicated sync role: ve_ views filter by the selectors of current_user, and this function is
SECURITY INVOKER on purpose.

Per table: build staging -> apply structure (create / alter / swap) -> apply data -> apply security ->
set metadata -> sync_log. Each table runs in its own sub-transaction: a failure is logged and the rest go on.

Tables are recreated (create / swap) or altered under an ACCESS EXCLUSIVE lock held until the end of the
call. For long runs call it per target (or per frequency) so locks are released between tables.

config_publi_table.selector_config overrides the selector parameters for one table
(keys "states", "psectors", "dscenarios"); defaults are restored after that table.
*/

DECLARE
	v_schema_filter text;
	v_targets text[];
	v_frequency text;
	v_reset boolean;
	v_defaults jsonb;
	v_old_path text;
	v_schema text;
	v_cfg publi.config_publi_table;
	v_res json;
	v_failed_schemas jsonb := '{}';
	v_selectors jsonb := '{}';
	v_staging json;
	v_structure json;
	v_data json;
	v_security json;
	v_metadata json;
	v_stg text;
	v_mode text;
	v_inserted int;
	v_updated int;
	v_deleted int;
	v_start timestamp;
	v_summary jsonb := '[]';
	v_ok int := 0;
	v_ko int := 0;
BEGIN
	v_old_path := current_setting('search_path');

	v_schema_filter := p_data -> 'data' ->> 'sourceSchema';
	v_frequency := p_data -> 'data' ->> 'frequency';
	v_reset := COALESCE((p_data -> 'data' ->> 'resetSelectors')::boolean, true);
	SELECT array_agg(value) INTO v_targets FROM json_array_elements_text(p_data -> 'data' -> 'targets');
	v_defaults := jsonb_strip_nulls(jsonb_build_object(
		'states', p_data -> 'data' -> 'states',
		'psectors', p_data -> 'data' -> 'psectors',
		'dscenarios', p_data -> 'data' -> 'dscenarios'));

	-- selectors once per source schema
	IF v_reset THEN
		FOR v_schema IN
			SELECT DISTINCT source_schema FROM publi.config_publi_table
			WHERE active
			AND (v_schema_filter IS NULL OR source_schema = v_schema_filter)
			AND (v_targets IS NULL OR target_name = ANY (v_targets))
			AND (v_frequency IS NULL OR sync_frequency = v_frequency)
		LOOP
			v_res := publi.gw_fct_publi_reset_selectors(json_build_object('data',
				v_defaults || jsonb_build_object('sourceSchema', v_schema)));
			IF v_res ->> 'status' = 'Accepted' THEN
				v_selectors := v_selectors || jsonb_build_object(v_schema, v_res -> 'body' -> 'data');
			ELSE
				v_failed_schemas := v_failed_schemas || jsonb_build_object(v_schema, v_res ->> 'NOSQLERR');
			END IF;
		END LOOP;
	END IF;

	FOR v_cfg IN
		SELECT * FROM publi.config_publi_table
		WHERE active
		AND (v_schema_filter IS NULL OR source_schema = v_schema_filter)
		AND (v_targets IS NULL OR target_name = ANY (v_targets))
		AND (v_frequency IS NULL OR sync_frequency = v_frequency)
		ORDER BY orderby NULLS LAST, id
	LOOP
		v_start := clock_timestamp();

		-- never publish with unknown selectors
		IF v_failed_schemas ? v_cfg.source_schema THEN
			INSERT INTO publi.sync_log (target_name, "mode", tstamp_start, tstamp_end, error)
			VALUES (v_cfg.target_name, 'error', v_start, clock_timestamp(),
				'selector reset failed: ' || (v_failed_schemas ->> v_cfg.source_schema));
			v_ko := v_ko + 1;
			v_summary := v_summary || jsonb_build_object('target', v_cfg.target_name, 'mode', 'error');
			CONTINUE;
		END IF;

		BEGIN
			IF v_cfg.selector_config IS NOT NULL THEN
				v_res := publi.gw_fct_publi_reset_selectors(json_build_object('data',
					v_defaults || v_cfg.selector_config || jsonb_build_object('sourceSchema', v_cfg.source_schema)));
				IF v_res ->> 'status' <> 'Accepted' THEN
					RAISE EXCEPTION 'selector_config failed: %', v_res ->> 'NOSQLERR';
				END IF;
			END IF;

			v_staging := publi.gw_fct_publi_build_staging(json_build_object('data', json_build_object('configId', v_cfg.id)));
			v_stg := v_staging -> 'body' -> 'data' ->> 'staging';

			v_structure := publi.gw_fct_publi_apply_structure(json_build_object('data',
				json_build_object('configId', v_cfg.id, 'staging', v_stg)));
			v_mode := v_structure -> 'body' -> 'data' ->> 'mode';

			IF v_mode IN ('alter', 'none') THEN
				v_data := publi.gw_fct_publi_apply_data(json_build_object('data',
					json_build_object('configId', v_cfg.id, 'staging', v_stg)));
				v_inserted := (v_data -> 'body' -> 'data' ->> 'inserted')::int;
				v_updated := (v_data -> 'body' -> 'data' ->> 'updated')::int;
				v_deleted := (v_data -> 'body' -> 'data' ->> 'deleted')::int;
			ELSE
				v_data := NULL;
				v_inserted := (v_staging -> 'body' -> 'data' ->> 'rows')::int;
				v_updated := 0;
				v_deleted := 0;
			END IF;

			v_security := publi.gw_fct_publi_apply_security(json_build_object('data', json_build_object('configId', v_cfg.id)));

			v_metadata := publi.gw_fct_publi_set_metadata(json_build_object('data', json_build_object(
				'configId', v_cfg.id,
				'decoded', v_staging -> 'body' -> 'data' -> 'decoded')));

			EXECUTE format('DROP TABLE IF EXISTS pg_temp.%I', v_stg);

			IF v_cfg.selector_config IS NOT NULL THEN
				v_res := publi.gw_fct_publi_reset_selectors(json_build_object('data',
					v_defaults || jsonb_build_object('sourceSchema', v_cfg.source_schema)));
			END IF;

			INSERT INTO publi.sync_log (target_name, "mode", rows_inserted, rows_updated, rows_deleted,
				structure_changed, details, tstamp_start, tstamp_end)
			VALUES (v_cfg.target_name, v_mode, v_inserted, v_updated, v_deleted,
				v_mode <> 'none',
				jsonb_build_object(
					'staging', v_staging -> 'body' -> 'data',
					'structure', v_structure -> 'body' -> 'data',
					'security', v_security -> 'body' -> 'data',
					'metadata', v_metadata -> 'body' -> 'data'),
				v_start, clock_timestamp());

			v_ok := v_ok + 1;
			v_summary := v_summary || jsonb_build_object('target', v_cfg.target_name, 'mode', v_mode,
				'inserted', v_inserted, 'updated', v_updated, 'deleted', v_deleted);

		EXCEPTION WHEN OTHERS THEN
			INSERT INTO publi.sync_log (target_name, "mode", tstamp_start, tstamp_end, error)
			VALUES (v_cfg.target_name, 'error', v_start, clock_timestamp(), SQLERRM);
			v_ko := v_ko + 1;
			v_summary := v_summary || jsonb_build_object('target', v_cfg.target_name, 'mode', 'error', 'error', SQLERRM);
		END;
	END LOOP;

	PERFORM set_config('search_path', v_old_path, true);

	RETURN json_build_object('status', 'Accepted',
		'body', json_build_object('data', json_build_object(
			'ok', v_ok,
			'failed', v_ko,
			'selectors', v_selectors,
			'failedSchemas', v_failed_schemas,
			'tables', v_summary)));

EXCEPTION WHEN OTHERS THEN
	PERFORM set_config('search_path', v_old_path, true);
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'SQLSTATE', SQLSTATE);
END;
$BODY$
LANGUAGE plpgsql VOLATILE
SET client_min_messages = warning;

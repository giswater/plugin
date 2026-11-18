/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION publi.gw_fct_publi_reset_selectors(p_data json)
RETURNS json AS
$BODY$

/*example
SELECT publi.gw_fct_publi_reset_selectors($${"data":{"sourceSchema":"ws", "states":[1], "psectors":[], "dscenarios":[]}}$$);
*/

DECLARE
	v_schema text;
	v_states int[];
	v_psectors int[];
	v_dscenarios int[];
	v_rec record;
	v_ref_table text;
	v_ref_col text;
	v_count int;
	v_selectors jsonb := '{}';
	v_nullkeys jsonb := '{}';
	v_warnings jsonb := '[]';
	v_feature text;
	v_cond text;
BEGIN
	v_schema := p_data -> 'data' ->> 'sourceSchema';
	IF v_schema IS NULL OR to_regnamespace(v_schema) IS NULL THEN
		RAISE EXCEPTION 'sourceSchema % does not exist', v_schema;
	END IF;

	SELECT array_agg(value::int) INTO v_states FROM json_array_elements_text(p_data -> 'data' -> 'states');
	SELECT array_agg(value::int) INTO v_psectors FROM json_array_elements_text(p_data -> 'data' -> 'psectors');
	SELECT array_agg(value::int) INTO v_dscenarios FROM json_array_elements_text(p_data -> 'data' -> 'dscenarios');

	-- filter selectors: always ALL ids, so new mapzones are never missed
	FOR v_rec IN
		SELECT * FROM (VALUES
			('selector_expl', 'expl_id', 'exploitation', 'expl_id'),
			('selector_macroexpl', 'macroexpl_id', 'macroexploitation', 'macroexpl_id'),
			('selector_sector', 'sector_id', 'sector', 'sector_id'),
			('selector_macrosector', 'macrosector_id', 'macrosector', 'macrosector_id'),
			('selector_municipality', 'muni_id', 'ext_municipality', 'muni_id'),
			('selector_hydrometer', 'state_id', 'ext_rtc_hydrometer_state', 'id')
		) AS t(sel_table, sel_col, fallback_table, fallback_col)
	LOOP
		IF to_regclass(format('%I.%I', v_schema, v_rec.sel_table)) IS NULL THEN
			CONTINUE;
		END IF;

		-- FK target wins over the fallback (e.g. selector_municipality -> utils.municipality)
		SELECT format('%I.%I', rn.nspname, rc.relname), af.attname
		INTO v_ref_table, v_ref_col
		FROM pg_constraint c
		JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]
		JOIN pg_class rc ON rc.oid = c.confrelid
		JOIN pg_namespace rn ON rn.oid = rc.relnamespace
		JOIN pg_attribute af ON af.attrelid = c.confrelid AND af.attnum = c.confkey[1]
		WHERE c.contype = 'f'
		AND c.conrelid = format('%I.%I', v_schema, v_rec.sel_table)::regclass
		AND a.attname = v_rec.sel_col
		LIMIT 1;

		IF v_ref_table IS NULL THEN
			IF to_regclass(format('%I.%I', v_schema, v_rec.fallback_table)) IS NULL THEN
				v_warnings := v_warnings || to_jsonb(format('%s: no source table found', v_rec.sel_table));
				CONTINUE;
			END IF;
			v_ref_table := format('%I.%I', v_schema, v_rec.fallback_table);
			v_ref_col := v_rec.fallback_col;
		END IF;

		EXECUTE format('DELETE FROM %I.%I WHERE cur_user = current_user', v_schema, v_rec.sel_table);
		EXECUTE format('INSERT INTO %I.%I (%I, cur_user) SELECT DISTINCT %I, current_user FROM %s WHERE %I IS NOT NULL',
			v_schema, v_rec.sel_table, v_rec.sel_col, v_ref_col, v_ref_table, v_ref_col);
		GET DIAGNOSTICS v_count = ROW_COUNT;
		v_selectors := v_selectors || jsonb_build_object(v_rec.sel_table, v_count);
	END LOOP;

	-- states: explicit list or all
	IF to_regclass(format('%I.selector_state', v_schema)) IS NOT NULL THEN
		EXECUTE format('DELETE FROM %I.selector_state WHERE cur_user = current_user', v_schema);
		IF v_states IS NULL THEN
			EXECUTE format('INSERT INTO %I.selector_state (state_id, cur_user) SELECT id, current_user FROM %I.value_state', v_schema, v_schema);
		ELSE
			EXECUTE format('INSERT INTO %I.selector_state (state_id, cur_user) SELECT id, current_user FROM %I.value_state WHERE id = ANY($1)', v_schema, v_schema)
			USING v_states;
		END IF;
		GET DIAGNOSTICS v_count = ROW_COUNT;
		v_selectors := v_selectors || jsonb_build_object('selector_state', v_count);
	END IF;

	-- scenario selectors: never ALL, only the explicit list (empty by default)
	IF to_regclass(format('%I.selector_psector', v_schema)) IS NOT NULL THEN
		EXECUTE format('DELETE FROM %I.selector_psector WHERE cur_user = current_user', v_schema);
		IF v_psectors IS NOT NULL THEN
			EXECUTE format('INSERT INTO %I.selector_psector (psector_id, cur_user) SELECT unnest($1), current_user', v_schema)
			USING v_psectors;
		END IF;
		v_selectors := v_selectors || jsonb_build_object('selector_psector', COALESCE(cardinality(v_psectors), 0));
	END IF;

	IF to_regclass(format('%I.selector_inp_dscenario', v_schema)) IS NOT NULL THEN
		EXECUTE format('DELETE FROM %I.selector_inp_dscenario WHERE cur_user = current_user', v_schema);
		IF v_dscenarios IS NOT NULL THEN
			EXECUTE format('INSERT INTO %I.selector_inp_dscenario (dscenario_id, cur_user) SELECT unnest($1), current_user', v_schema)
			USING v_dscenarios;
		END IF;
		v_selectors := v_selectors || jsonb_build_object('selector_inp_dscenario', COALESCE(cardinality(v_dscenarios), 0));
	END IF;

	-- features no selector can reach: EXISTS never matches a NULL key
	FOREACH v_feature IN ARRAY ARRAY['arc', 'node', 'connec', 'gully', 'link', 'element']
	LOOP
		IF to_regclass(format('%I.%I', v_schema, v_feature)) IS NULL THEN
			CONTINUE;
		END IF;

		SELECT string_agg(format('%I IS NULL', attname), ' OR ')
		INTO v_cond
		FROM pg_attribute
		WHERE attrelid = format('%I.%I', v_schema, v_feature)::regclass
		AND attname IN ('expl_id', 'sector_id', 'muni_id')
		AND NOT attisdropped;

		IF v_cond IS NULL THEN
			CONTINUE;
		END IF;

		EXECUTE format('SELECT count(*) FROM %I.%I WHERE state > 0 AND (%s)', v_schema, v_feature, v_cond) INTO v_count;
		IF v_count > 0 THEN
			v_nullkeys := v_nullkeys || jsonb_build_object(v_feature, v_count);
		END IF;
	END LOOP;

	RETURN json_build_object('status', 'Accepted',
		'body', json_build_object('data', json_build_object(
			'sourceSchema', v_schema,
			'selectors', v_selectors,
			'nullKeys', v_nullkeys,
			'warnings', v_warnings)));

EXCEPTION WHEN OTHERS THEN
	RETURN json_build_object('status', 'Failed', 'NOSQLERR', SQLERRM, 'SQLSTATE', SQLSTATE);
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

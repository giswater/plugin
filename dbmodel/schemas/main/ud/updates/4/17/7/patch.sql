/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- 4.17.6 SAVE-DROP of cat_link dropped ve_link and its dependents, then RESTORE
-- failed when pg_get_viewdef did not match the literal diameter block. The function
-- swallowed the error, so the update committed with those views gone and batch 969
-- still in temp_view_dependencies. Replay that batch. Also drop a leftover cat_pnom
-- column if a manual restore kept NULL::numeric AS cat_pnom (#969).
DO $fix$
DECLARE
	v_result json;
	v_replacements json := $json$[
		{"from":"cat_link.dnom","to":"cat_link.geom1"},
		{"from":"cat_link.dint","to":"cat_link.geom2"},
		{"from":"cat_dnom","to":"cat_geom1"},
		{"from":"cat_dint","to":"cat_geom2"},
		{"from":",\\s*cat_link\\.pnom\\s+AS\\s+cat_pnom","to":"","regex":true},
		{"from":",\\s*NULL::numeric\\s+AS\\s+cat_pnom","to":"","regex":true},
		{"from":",\\s*ve_link\\.cat_pnom\\M","to":"","regex":true},
		{"from":",\\s*\\mcat_pnom\\M","to":"","regex":true}
	]$json$::json;
	v_has_batch boolean;
	v_has_ve_link boolean;
	v_has_cat_pnom boolean;
BEGIN
	v_has_batch := to_regclass('temp_view_dependencies') IS NOT NULL
		AND EXISTS (SELECT 1 FROM temp_view_dependencies WHERE batch_id = 969);
	v_has_ve_link := to_regclass('ve_link') IS NOT NULL;
	v_has_cat_pnom := v_has_ve_link AND EXISTS (
		SELECT 1
		FROM information_schema.columns
		WHERE table_schema = current_schema()
			AND table_name = 've_link'
			AND column_name = 'cat_pnom'
	);

	IF v_has_batch AND NOT v_has_ve_link THEN
		v_result := gw_fct_admin_manage_view_dependencies(json_build_object(
			'data', json_build_object(
				'action', 'RESTORE',
				'batchId', 969,
				'replacements', v_replacements
			)
		));
	ELSIF v_has_cat_pnom THEN
		v_result := gw_fct_admin_manage_view_dependencies($json${"data":{"action":"SAVE-DROP","rootViews":["ve_link"],"saveRoots":true,"batchId":970}}$json$::json);
		IF COALESCE(v_result->>'status', '') <> 'Accepted' THEN
			RAISE EXCEPTION 'view save-drop failed: %', v_result;
		END IF;
		v_result := gw_fct_admin_manage_view_dependencies(json_build_object(
			'data', json_build_object(
				'action', 'RESTORE',
				'batchId', 970,
				'replacements', v_replacements
			)
		));
	ELSIF NOT v_has_ve_link THEN
		RAISE EXCEPTION 've_link is missing and temp_view_dependencies batch 969 has no saved definitions';
	END IF;

	IF v_result IS NOT NULL AND COALESCE(v_result->>'status', '') <> 'Accepted' THEN
		RAISE EXCEPTION 'view restore failed: %', v_result;
	END IF;
END
$fix$;

-- Append parent_id at the end.
CREATE OR REPLACE VIEW v_ui_rpt_cat_result AS
SELECT DISTINCT ON (rpt_cat_result.result_id)
	rpt_cat_result.result_id,
	e.exploitation_names AS expl_id,
	rpt_cat_result.sector_id,
	t2.idval AS network_type,
	t1.idval AS status,
	rpt_cat_result.iscorporate,
	rpt_cat_result.descript,
	rpt_cat_result.exec_date,
	rpt_cat_result.cur_user,
	rpt_cat_result.export_options,
	rpt_cat_result.network_stats,
	rpt_cat_result.inp_options,
	rpt_cat_result.rpt_stats,
	rpt_cat_result.addparam,
	rpt_cat_result.isvalidated,
	rpt_cat_result.parent_id
FROM rpt_cat_result
	JOIN selector_expl s ON (s.expl_id = ANY(rpt_cat_result.expl_id) AND s.cur_user = CURRENT_USER) OR rpt_cat_result.expl_id = ARRAY[NULL::integer]
	LEFT JOIN inp_typevalue t1 ON rpt_cat_result.status::text = t1.id::text
	LEFT JOIN inp_typevalue t2 ON rpt_cat_result.network_type = t2.id
	LEFT JOIN LATERAL (
		SELECT array_agg(ex.name) AS exploitation_names
		FROM unnest(rpt_cat_result.expl_id) AS x(expl_id)
		JOIN exploitation ex ON ex.expl_id = x.expl_id
	) e ON true
WHERE t1.typevalue = 'inp_result_status'
AND t2.typevalue = 'inp_options_networkmode';

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- Append parent_id at the end.
CREATE OR REPLACE VIEW v_ui_rpt_cat_result AS
SELECT DISTINCT ON (rpt_cat_result.result_id)
	rpt_cat_result.result_id,
	e.exploitation_names AS expl_id,
	rpt_cat_result.sector_id,
	rpt_cat_result.dma_id,
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

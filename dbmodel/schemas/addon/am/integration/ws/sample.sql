/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = am, public;

INSERT INTO config_material_def (material, pleak, age_max, age_med, age_min, builtdate_vdef, compliance)
SELECT id, 0.16, 58, 50, 42, 1964, 10
FROM PARENT_SCHEMA.cat_material
WHERE active = true
ON CONFLICT (material) DO NOTHING;

INSERT INTO config_catalog_def (arccat_id, dnom, cost_constr, cost_repmain, compliance)
SELECT id AS arccat_id,
	dnom::NUMERIC,
	round(dnom::NUMERIC * 3 / 5 + 70) AS cost_constr,
	round(dnom::NUMERIC * 9 / 5 + 310) AS cost_repmain,
	10 AS compliance
FROM PARENT_SCHEMA.cat_arc
WHERE dnom IS NOT NULL
ON CONFLICT (arccat_id) DO NOTHING;

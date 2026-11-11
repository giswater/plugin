/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

-- Suppress NOTICE messages
SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(6);

-- Avoid corporate sector conflicts with sample results
UPDATE rpt_cat_result SET iscorporate = false WHERE iscorporate IS TRUE;

INSERT INTO rpt_cat_result (result_id, status, sector_id, network_type, expl_id, iscorporate)
VALUES ('-990', 2, ARRAY[1], '4', ARRAY[1], false);

-- Direct match: rpt node_id = connec_id
INSERT INTO rpt_node_stats (
	node_id, result_id, demand_max, demand_min, demand_avg,
	press_max, press_min, press_avg, quality_max, quality_min, quality_avg
)
VALUES (
	'3099', '-990', 12.5, 1.5, 6.25,
	45.1, 20.2, 32.5, 0.1, 0.0, 0.05
);

-- VN{link_id} match: use an existing link of another sample connec
INSERT INTO rpt_node_stats (
	node_id, result_id, demand_max, demand_min, demand_avg,
	press_max, press_min, press_avg, quality_max, quality_min, quality_avg
)
SELECT
	concat('VN', l.link_id), '-990', 9.0, 0.5, 4.5,
	40.0, 18.0, 29.0, 0.2, 0.0, 0.1
FROM link l
WHERE l.feature_id = 3101
ORDER BY l.link_id
LIMIT 1;

SELECT is(
	(gw_fct_epa2data($${
		"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE},
		"data":{"resultId":"-990", "isCorporate":true}
	}$$)::json)->>'status',
	'Accepted',
	'gw_fct_epa2data corporate returns Accepted'
);

SELECT is(
	(SELECT demand_max FROM connec_add WHERE connec_id = 3099),
	12.50,
	'connec_add.demand_max filled from node_id = connec_id'
);

SELECT is(
	(SELECT demand_min FROM connec_add WHERE connec_id = 3099),
	1.50,
	'connec_add.demand_min filled from node_id = connec_id'
);

SELECT is(
	(SELECT demand_avg FROM connec_add WHERE connec_id = 3099),
	6.25,
	'connec_add.demand_avg filled from node_id = connec_id'
);

SELECT is(
	(SELECT press_max FROM connec_add WHERE connec_id = 3099),
	45.10,
	'connec_add.press_max still filled'
);

SELECT is(
	(SELECT demand_max FROM connec_add WHERE connec_id = 3101),
	9.00,
	'connec_add.demand_max filled from VN{link_id}'
);

SELECT finish();

ROLLBACK;

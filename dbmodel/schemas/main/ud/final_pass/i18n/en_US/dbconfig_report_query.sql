/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;
UPDATE config_report AS t SET query_text = v.text FROM (
	VALUES
	(100, 'SELECT name as "Exploitation", arccat_id as "Arc Catalog", sum(gis_length) as "Length" FROM ve_arc JOIN exploitation USING (expl_id) GROUP BY arccat_id, name'),
	(101, 'SELECT e.name as "Exploitation", vec.connec_id, vec.code, vec.customer_code FROM ve_connec vec JOIN exploitation e USING (expl_id) '),
	(105, 'SELECT name as "Exploitation", node_type as "Node type", count(*) as "Units" FROM ve_node JOIN exploitation USING (expl_id) GROUP BY node_type, name')
) AS v(id, text)
WHERE t.id = v.id;

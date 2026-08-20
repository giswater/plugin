/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;
UPDATE config_param_system AS t SET value = v.value FROM (
	VALUES
	('admin_currency', '{"id":"EUR", "descript":"EURO", "symbol":"€", "separator":".", "decimals":true}'),
    ('admin_currency', '{"id":"EUR", "descript":"EURO", "symbol":"€", "separator":".", "decimals":true}')
) AS v(parameter, value)
WHERE t.parameter = v.parameter;

UPDATE value_state AS t SET name = v.name, observ = v.observ FROM (
	VALUES
	(0, 'OBSOLETE', NULL),
    (1, 'OPERATIVE', NULL),
    (2, 'PLANIFIED', NULL),
    (0, 'OBSOLETE', NULL),
    (1, 'OPERATIVE', NULL),
    (2, 'PLANIFIED', NULL)
) AS v(id, name, observ)
WHERE t.id = v.id;

UPDATE value_state_type AS t SET name = v.name FROM (
	VALUES
	(1, 'OBSOLETE'),
    (100, 'OBSOLET-FICTICIUS'),
    (2, 'OPERATIVE'),
    (3, 'PLANIFIED'),
    (4, 'RECONSTRUCT'),
    (5, 'PROVISIONAL'),
    (99, 'FICTICIUS'),
    (1, 'OBSOLETE'),
    (100, 'OBSOLET-FICTICIUS'),
    (2, 'OPERATIVE'),
    (3, 'PLANIFIED'),
    (4, 'RECONSTRUCT'),
    (5, 'PROVISIONAL'),
    (99, 'FICTICIUS')
) AS v(id, name)
WHERE t.id = v.id;
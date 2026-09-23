/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- en_US toolbox alias was left in Spanish (id 2768). es_ES/ca_ES keep their own alias.
UPDATE config_toolbox
	SET alias = 'Mapzones analysis'
	WHERE id = 2768
	AND (SELECT language FROM sys_version ORDER BY id DESC LIMIT 1) = 'en_US';

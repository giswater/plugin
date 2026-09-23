/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- Source alias for i18n. The searcher reads no_TR schemas, which skip final_pass i18n.
UPDATE config_toolbox
	SET alias = 'Mapzones analysis'
	WHERE id = 2768;

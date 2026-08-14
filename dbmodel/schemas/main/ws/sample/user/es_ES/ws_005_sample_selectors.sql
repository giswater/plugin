/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = "SCHEMA_NAME", public, pg_catalog;

INSERT INTO selector_expl VALUES (1, current_user);
INSERT INTO selector_expl VALUES (2, current_user);
INSERT INTO selector_expl VALUES (0, current_user);

INSERT INTO selector_state VALUES (1, current_user);

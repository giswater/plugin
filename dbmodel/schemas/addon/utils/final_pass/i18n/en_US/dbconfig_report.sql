/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;
UPDATE config_report AS t SET alias = v.alias, descript = v.descript FROM (
	VALUES
	(100, 'Conduit length by exploitation and catalog', NULL),
    (101, 'Connecs by exploitation', NULL),
    (105, 'Nodes by exploitation and type', NULL),
    (100, 'Pipe length by Exploitation and Catalog', NULL),
    (101, 'Connecs by Exploitation', NULL),
    (102, 'Losses & NRW by Exploitation, Dma & Period', NULL),
    (103, 'Total Losses & NRW by Exploitation', NULL),
    (104, 'Total Losses & NRW by Dma', NULL)
) AS v(id, alias, descript)
WHERE t.id = v.id;
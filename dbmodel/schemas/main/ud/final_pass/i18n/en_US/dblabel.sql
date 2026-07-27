/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;
UPDATE sys_label AS t SET idval = v.idval FROM (
	VALUES
	(1001, 'INFO'),
    (1002, 'WARNING'),
    (1003, 'ERROR'),
    (1004, 'CRITICAL ERRORS'),
    (1005, 'HINT'),
    (1006, 'WARNING-403'),
    (1007, 'ERROR-403'),
    (1008, 'ERROR-357'),
    (2000, ' '),
    (2007, '-------'),
    (2008, '--------'),
    (2009, '---------'),
    (2010, '----------'),
    (2011, '-----------'),
    (2014, '--------------'),
    (2022, '----------------------'),
    (2025, '-------------------------'),
    (2030, '------------------------------'),
    (2049, '-------------------------------------------------'),
    (3001, 'INFO'),
    (3002, 'WARNINGS'),
    (3003, 'ERRORS'),
    (3006, 'ARC DIVIDE = TRUE'),
    (3008, 'ARC DIVIDE = FALSE'),
    (3009, 'RESUME'),
    (3010, 'CHECK SYSTEM'),
    (3011, 'CHECK DB DATA'),
    (3012, 'DETAILS'),
    (3013, E'To check CRITICAL ERRORS or WARNINGS, execute a query FROM anl_table WHERE fid=error number AND current_user. For example:\n\nSELECT * FROM MySchema.anl_arc WHERE fid = Myfid AND cur_user=current_user;\n\nOnly the errors with anl_table next to the number can be checked this way. Using Giswater Toolbox it''s also posible to check these errors.')
) AS v(id, idval)
WHERE t.id = v.id;
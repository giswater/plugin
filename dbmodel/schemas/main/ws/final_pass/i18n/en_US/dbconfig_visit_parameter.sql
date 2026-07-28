/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;
UPDATE config_visit_parameter AS t SET descript = v.descript FROM (
	VALUES
	('clean_node', 'Clean of node'),
    ('defect_node', 'Defects of node'),
    ('incident_comment', 'incident_comment'),
    ('incident_type', 'incident type'),
    ('insp_observ', 'Inspection observations'),
    ('photo', 'Photography'),
    ('sediments_node', 'Sediments in node'),
    ('leak_arc', 'minor leak on arc'),
    ('leak_connec', 'minor leak on connec'),
    ('leak_link', 'minor leak on link')
) AS v(id, descript)
WHERE t.id = v.id;
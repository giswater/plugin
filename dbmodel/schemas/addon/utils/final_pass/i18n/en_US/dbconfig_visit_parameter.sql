/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;
UPDATE config_visit_parameter AS t SET descript = v.descript FROM (
	VALUES
	('clean_arc', 'Clean of arc'),
    ('clean_connec', 'Clean of connec'),
    ('clean_gully', 'Clean of gully'),
    ('clean_link', 'Clean of link'),
    ('defect_arc', 'Defects of arc'),
    ('defect_connec', 'Defects of connec'),
    ('defect_gully', 'Defects of gully'),
    ('defect_link', 'Defects of link'),
    ('sediments_arc', 'Sediments in arc'),
    ('sediments_connec', 'Sediments in connec'),
    ('sediments_gully', 'Sediments in gully'),
    ('sediments_link', 'Sediments in link'),
    ('smells_gully', 'Smells of gully'),
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
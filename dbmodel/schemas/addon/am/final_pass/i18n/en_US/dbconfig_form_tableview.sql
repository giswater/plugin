/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = am, public;
UPDATE config_form_tableview AS t SET alias = v.alias FROM (
	VALUES
	('cat_result', 'budget', 'Budget'),
    ('cat_result', 'cur_user', 'Current User'),
    ('cat_result', 'descript', 'Descript'),
    ('cat_result', 'dnom', 'DNOM'),
    ('cat_result', 'expl_id', 'Expl Id'),
    ('cat_result', 'features', 'Features'),
    ('cat_result', 'iscorporate', 'Corporate'),
    ('cat_result', 'material_id', 'Material Id'),
    ('cat_result', 'presszone_id', 'Presszone Id'),
    ('cat_result', 'report', 'Report'),
    ('cat_result', 'result_id', 'Result Id'),
    ('cat_result', 'result_name', 'Result Name'),
    ('cat_result', 'result_type', 'Type'),
    ('cat_result', 'status', 'Status'),
    ('cat_result', 'target_year', 'Horizon Year'),
    ('cat_result', 'tstamp', 'Timestamp')
) AS v(objectname, columnname, alias)
WHERE t.objectname = v.objectname AND t.columnname = v.columnname;
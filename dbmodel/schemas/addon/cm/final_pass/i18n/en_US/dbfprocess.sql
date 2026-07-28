/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = cm, public, public;
UPDATE sys_fprocess AS t SET except_msg = v.except_msg, info_msg = v.info_msg, fprocess_name = v.fprocess_name FROM (
	VALUES
	(100, 'null value on the column %check_column% of %table_name%.', 'The %check_column% on %table_name% have correct values.', 'Check nulls consistence'),
    (200, 'There are some users with no team assigned.', 'All users have a team assigned.', 'Check users consistence'),
    (201, 'teams with no users assigned.', 'All teams have users assigned.', 'Check teams consistence'),
    (202, 'There are some orphan nodes.', 'There aren''t orphan nodes.', 'Check orphan nodes'),
    (203, 'nodes duplicated with state 1.', 'There are no nodes duplicated with state 1', 'Check duplicated nodes')
) AS v(fid, except_msg, info_msg, fprocess_name)
WHERE t.fid = v.fid;
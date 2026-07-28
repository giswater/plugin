/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = cm, public, public;
UPDATE sys_table AS t SET alias = v.alias, descript = v.descript FROM (
	VALUES
	('%_camp_arc', NULL, 've_ws44_1709_camp_arc'),
    ('%_camp_connec', NULL, 've_ws44_1709_camp_connec'),
    ('%_camp_link', NULL, 've_ws44_1709_camp_link'),
    ('%_camp_node', NULL, 've_ws44_1709_camp_node'),
    ('%_lot_arc', NULL, 've_ws44_1709_lot_arc'),
    ('%_lot_connec', NULL, 've_ws44_1709_lot_connec'),
    ('%_lot_link', NULL, 've_ws44_1709_lot_link'),
    ('%_lot_node', NULL, 've_ws44_1709_lot_node')
) AS v(id, alias, descript)
WHERE t.id = v.id;
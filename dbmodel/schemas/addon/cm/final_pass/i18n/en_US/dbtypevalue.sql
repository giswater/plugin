/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = cm, public, public;
UPDATE sys_typevalue AS t SET idval = v.idval, descript = v.descript FROM (
	VALUES
	('1', 'campaign_feature_status', 'PLANIFIED', NULL),
    ('1', 'campaign_status', 'PLANIFYING', NULL),
    ('1', 'campaign_type', 'REVIEW', NULL),
    ('1', 'lot_feature_status', 'PLANIFIED', NULL),
    ('1', 'lot_status', 'PLANIFYING', NULL),
    ('10', 'campaign_status', 'CANCELED', NULL),
    ('10', 'lot_status', 'CANCELED', NULL),
    ('2', 'campaign_feature_status', 'NOT VISITED', NULL),
    ('2', 'campaign_status', 'PLANIFIED', NULL),
    ('2', 'campaign_type', 'VISIT', NULL),
    ('2', 'lot_feature_status', 'NOT VISITED', NULL),
    ('2', 'lot_status', 'PLANIFIED', NULL),
    ('3', 'campaign_feature_status', 'VISITED', NULL),
    ('3', 'campaign_status', 'ASSIGNED', NULL),
    ('3', 'campaign_type', 'INVENTORY', NULL),
    ('3', 'lot_feature_status', 'VISITED', NULL),
    ('3', 'lot_status', 'ASSIGNED', NULL),
    ('4', 'campaign_feature_status', 'VISIT AGAIN', NULL),
    ('4', 'campaign_status', 'ON GOING', NULL),
    ('4', 'lot_feature_status', 'VISIT AGAIN', NULL),
    ('4', 'lot_status', 'ON GOING', NULL),
    ('5', 'campaign_feature_status', 'ACCEPTED', NULL),
    ('5', 'campaign_status', 'STAND-BY', NULL),
    ('5', 'lot_feature_status', 'ACCEPTED', NULL),
    ('5', 'lot_status', 'STAND-BY', NULL),
    ('6', 'campaign_feature_status', 'CANCELED', NULL),
    ('6', 'campaign_status', 'EXECUTED', NULL),
    ('6', 'lot_feature_status', 'CANCELED', NULL),
    ('6', 'lot_status', 'EXECUTED', NULL),
    ('7', 'campaign_status', 'REJECTED', NULL),
    ('7', 'lot_status', 'REJECTED', NULL),
    ('8', 'campaign_status', 'READY-TO-ACCEPT', NULL),
    ('8', 'lot_status', 'READY-TO-ACCEPT', NULL),
    ('9', 'campaign_status', 'ACCEPTED', NULL),
    ('9', 'lot_status', 'ACCEPTED', NULL),
    ('lyt_buttons', 'layout_name_typevalue', 'lyt_buttons', NULL)
) AS v(id, typevalue, idval, descript)
WHERE t.id = v.id AND t.typevalue = v.typevalue;
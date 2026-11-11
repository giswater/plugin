/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

--2023/05/04
UPDATE config_form_fields SET hidden = false where formname like '%_arc%' and columnname in ('flow_max', 'flow_min', 'flow_avg', 'vel_max','vel_min','vel_avg');
UPDATE config_form_fields SET hidden = false where formname like '%_node%' and columnname 
in ('demand_max', 'demand_min', 'demand_avg', 'press_max','press_min','press_avg', 'head_max', 'head_min', 'head_avg', 'quality_max','quality_min','quality_avg');
UPDATE config_form_fields SET hidden = false where formname like '%_connec%' and columnname in ('demand_max','demand_min','demand_avg','press_max','press_min','press_avg');

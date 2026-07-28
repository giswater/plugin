/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3202

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_arc_node_values() RETURNS trigger AS $BODY$
DECLARE 

v_nodecat text;
v_message text;

	
BEGIN 

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	IF COALESCE((SELECT value::boolean FROM config_param_user WHERE parameter = 'edit_disable_update_nodevalues' AND cur_user = current_user), FALSE) = FALSE THEN
		
		UPDATE arc a SET nodetype_1 = cn.node_type, node_top_elev_1 = top_elev, node_custom_top_elev_1 = custom_top_elev,
		node_elev_1 = elev, node_custom_elev_1 = custom_elev
		FROM node n
		JOIN cat_node cn ON cn.id::text = n.nodecat_id::text
		WHERE a.arc_id = NEW.arc_id AND node_id = node_1;

		UPDATE arc a SET nodetype_2 = cn.node_type ,node_top_elev_2 = top_elev, node_custom_top_elev_2 = custom_top_elev,
		node_elev_2 = elev, node_custom_elev_2 = custom_elev
		FROM node n
		JOIN cat_node cn ON cn.id::text = n.nodecat_id::text
		WHERE a.arc_id = NEW.arc_id AND node_id = node_2;
		
	END IF;

RETURN NEW;
		
END; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



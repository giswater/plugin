/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 1210

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_edit_inp_node()
RETURNS trigger AS
$BODY$
DECLARE
    v_node_table varchar;
    v_man_table varchar;
    v_sql varchar;
    v_old_nodetype varchar;
    v_new_nodetype varchar;
    v_input json;


BEGIN

    EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
    v_node_table:= TG_ARGV[0];

    -- Control insertions ID
    IF TG_OP = 'INSERT' THEN

        IF v_node_table = 'inp_pump_additional' THEN
            INSERT INTO inp_pump_additional (node_id, order_id, power, curve_id, speed, pattern_id, status, effic_curve_id, energy_price, energy_pattern_id)
            VALUES (NEW.node_id, NEW.order_id, NEW.power, NEW.curve_id, NEW.speed, NEW.pattern_id, NEW.status, NEW.effic_curve_id, NEW.energy_price, NEW.energy_pattern_id);
        ELSE
            EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
            "data":{"message":"1030", "function":"1310","parameters":null}}$$);';
        END IF;

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

	-- Update of topocontrol fields only when one if it has changed in order to prevent to be triggered the topocontrol without changes
	IF  (NEW.top_elev <> OLD.top_elev) OR (NEW.custom_top_elev <> OLD.custom_top_elev) OR (NEW.ymax <> OLD.ymax) OR
		(NEW.elev <> OLD.elev)  OR (NEW.custom_elev <> OLD.custom_elev) OR
		(NEW.top_elev IS NULL AND OLD.top_elev IS NOT NULL) OR (NEW.top_elev IS NOT NULL AND OLD.top_elev IS NULL) OR
		(NEW.custom_top_elev IS NULL AND OLD.custom_top_elev IS NOT NULL) OR (NEW.custom_top_elev IS NOT NULL AND OLD.custom_top_elev IS NULL) OR
		(NEW.ymax IS NULL AND OLD.ymax IS NOT NULL) OR (NEW.ymax IS NOT NULL AND OLD.ymax IS NULL) OR
		(NEW.elev IS NULL AND OLD.elev IS NOT NULL) OR (NEW.elev IS NOT NULL AND OLD.elev IS NULL) OR
		(NEW.custom_elev IS NULL AND OLD.custom_elev IS NOT NULL) OR (NEW.custom_elev IS NOT NULL AND OLD.custom_elev IS NULL) THEN
			UPDATE	node SET top_elev=NEW.top_elev, custom_top_elev=NEW.custom_top_elev, ymax=NEW.ymax, elev=NEW.elev, custom_elev=NEW.custom_elev
			WHERE node_id = OLD.node_id;
	END IF;

	-- State
	IF (NEW.state::text != OLD.state::text) THEN
		UPDATE node SET state=NEW.state WHERE node_id = OLD.node_id;
	END IF;

	-- The geom
	IF st_equals(NEW.the_geom, OLD.the_geom) IS FALSE  THEN
		UPDATE node SET the_geom=NEW.the_geom WHERE node_id = OLD.node_id;
	END IF;

	--update elevation from raster
	IF (SELECT json_extract_path_text(value::json,'activated')::boolean FROM config_param_system WHERE parameter='admin_raster_dem') IS TRUE
		 AND (NEW.top_elev IS NULL) AND
		(SELECT upper(value)  FROM config_param_user WHERE parameter = 'edit_update_elevation_from_dem' and cur_user = current_user) = 'TRUE' THEN
		NEW.top_elev = (SELECT ST_Value(rast,1,NEW.the_geom,false) FROM v_raster_dem WHERE id =
		(SELECT id FROM v_raster_dem WHERE st_dwithin (envelope, NEW.the_geom, 1) LIMIT 1));
	END IF;

        UPDATE node
        SET nodecat_id=NEW.nodecat_id, sector_id=NEW.sector_id, annotation=NEW.annotation, state_type=NEW.state_type
        WHERE node_id=OLD.node_id;

        IF v_node_table = 'inp_junction' THEN
            UPDATE inp_junction
			SET y0=NEW.y0, ysur=NEW.ysur, apond=NEW.apond, outfallparam = NEW.outfallparam::json
			WHERE node_id=OLD.node_id;

        ELSIF v_node_table = 'inp_divider' THEN
            UPDATE inp_divider
			SET divider_type=NEW.divider_type, arc_id=NEW.arc_id, curve_id=NEW.curve_id,qmin=NEW.qmin,ht=NEW.ht,cd=NEW.cd,y0=NEW.y0, ysur=NEW.ysur, apond=NEW.apond
			WHERE node_id=OLD.node_id;

        ELSIF v_node_table = 'inp_storage' THEN
            UPDATE inp_storage
			SET storage_type=NEW.storage_type,curve_id=NEW.curve_id,a1=NEW.a1,a2=NEW.a2,a0=NEW.a0,fevap=NEW.fevap,sh=NEW.sh,hc=NEW.hc,imd=NEW.imd,y0=NEW.y0, ysur=NEW.ysur
			WHERE node_id=OLD.node_id;

        ELSIF v_node_table = 'inp_outfall' THEN
            UPDATE inp_outfall
			SET outfall_type=NEW.outfall_type,stage=NEW.stage,curve_id=NEW.curve_id,timser_id=NEW.timser_id,gate=NEW.gate
			WHERE node_id=OLD.node_id;

		ELSIF v_node_table = 'inp_netgully' THEN

			--get default values
	        IF (NEW.outlet_type IS NULL) THEN
	            NEW.outlet_type := (SELECT "value" FROM config_param_user WHERE "parameter"='epa_gully_outlet_type_vdefault' AND "cur_user"="current_user"() LIMIT 1);
	        END IF;

	        IF (NEW.gully_method IS NULL) THEN
	            NEW.gully_method := (SELECT "value" FROM config_param_user WHERE "parameter"='epa_gully_method_vdefault' AND "cur_user"="current_user"() LIMIT 1);
	        END IF;

	        IF NEW.weir_cd IS NULL AND NEW.outlet_type='W/0' THEN
	            NEW.gully_method := (SELECT "value" FROM config_param_user WHERE "parameter"='epa_gully_weir_cd_vdefault' AND "cur_user"="current_user"() LIMIT 1);
	        ELSIF NEW.orifice_cd IS NULL AND NEW.outlet_type='W/0' THEN
	            NEW.gully_method := (SELECT "value" FROM config_param_user WHERE "parameter"='epa_gully_orifice_cd_vdefault' AND "cur_user"="current_user"() LIMIT 1);
	        END IF;

	        IF (NEW.efficiency IS NULL) THEN
	            NEW.efficiency := (SELECT "value" FROM config_param_user WHERE "parameter"='epa_gully_efficiency_vdefault' AND "cur_user"="current_user"() LIMIT 1);
	        END IF;

        	UPDATE node
	        SET custom_top_elev=NEW.custom_top_elev
	        WHERE node_id=OLD.node_id;

            UPDATE man_netgully
			SET units=NEW.units,units_placement=NEW.units_placement,gullycat_id=NEW.gullycat_id,groove=NEW.groove,groove_height=NEW.groove_height,
			groove_length=NEW.groove_length
			WHERE node_id=OLD.node_id;

			UPDATE inp_netgully
	        SET custom_length=NEW.custom_length, efficiency=NEW.efficiency,
	        outlet_type=NEW.outlet_type,  custom_width=NEW.custom_width,
	        custom_depth=NEW.custom_depth, gully_method=NEW.gully_method, weir_cd=NEW.weir_cd, orifice_cd=NEW.orifice_cd,
	        custom_a_param=NEW.custom_a_param, custom_b_param=NEW.custom_b_param, ysur=NEW.ysur,y0=NEW.y0,apond=NEW.apond
	        WHERE node_id=OLD.node_id;

		ELSIF v_node_table = 'inp_inlet' THEN

			UPDATE inp_inlet
			SET y0=NEW.y0, ysur=NEW.ysur, apond=NEW.apond, inlet_type=NEW.inlet_type, outlet_type=NEW.outlet_type, gully_method=NEW.gully_method,custom_top_elev=NEW.custom_top_elev,
			custom_depth=NEW.custom_depth, inlet_length=NEW.inlet_length, inlet_width=NEW.inlet_width, cd1=NEW.cd1, cd2=NEW.cd2, efficiency=NEW.efficiency
			WHERE node_id=OLD.node_id;
        END IF;

        v_input = concat('{"feature":{"type":"node", "childLayer":"',v_node_table,'", "id":"',NEW.node_id,'"}}');
        -- inp2man_values
		PERFORM gw_fct_man2inp_values(v_input);

        RETURN NEW;


    ELSIF TG_OP = 'DELETE' THEN
        EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"1032", "function":"1210","parameters":null}}$$);';

    END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION NODE: 3140


CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_ve_epa()
RETURNS trigger AS
$BODY$

DECLARE
v_epatype varchar;


BEGIN

    EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
    v_epatype:= TG_ARGV[0];


    -- Control insertions ID
    IF TG_OP = 'INSERT' THEN
        EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"1030", "function":"3140","parameters":null}}$$);';
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

		IF v_epatype = 'junction' THEN
            UPDATE inp_junction
            SET y0=NEW.y0, ysur=NEW.ysur, apond=NEW.apond, outfallparam = NEW.outfallparam::json
            WHERE node_id=OLD.node_id;

        ELSIF v_epatype = 'storage' THEN
            UPDATE inp_storage
            SET storage_type=NEW.storage_type,curve_id=NEW.curve_id,a1=NEW.a1,a2=NEW.a2,a0=NEW.a0,fevap=NEW.fevap,sh=NEW.sh,hc=NEW.hc,imd=NEW.imd,y0=NEW.y0, ysur=NEW.ysur
            WHERE node_id=OLD.node_id;

        ELSIF v_epatype = 'outfall' THEN
            UPDATE inp_outfall
            SET outfall_type=NEW.outfall_type,stage=NEW.stage,curve_id=NEW.curve_id,timser_id=NEW.timser_id,gate=NEW.gate
            WHERE node_id=OLD.node_id;

        ELSIF v_epatype = 'conduit' THEN
            UPDATE inp_conduit
            SET barrels=NEW.barrels,culvert=NEW.culvert,kentry=NEW.kentry,kexit=NEW.kexit,kavg=NEW.kavg,flap=NEW.flap,q0=NEW.q0
            WHERE arc_id=OLD.arc_id;

        ELSIF v_epatype = 'pump' THEN
            UPDATE inp_pump
            SET curve_id=NEW.curve_id,status=NEW.status,startup=NEW.startup,shutoff=NEW.shutoff
            WHERE arc_id=OLD.arc_id;

        ELSIF v_epatype = 'virtual' THEN
            UPDATE inp_virtual
            SET fusion_node=NEW.fusion_node,add_length=NEW.add_length
            WHERE arc_id=OLD.arc_id;

        ELSIF v_epatype = 'netgully' THEN
            UPDATE inp_netgully
            SET y0=NEW.y0, ysur=NEW.ysur, apond=NEW.apond, outlet_type=NEW.outlet_type, custom_width=NEW.custom_width, custom_length=NEW.custom_length, custom_depth=NEW.custom_depth,
            gully_method=NEW.gully_method, weir_cd=NEW.weir_cd, orifice_cd=NEW.orifice_cd, custom_a_param=NEW.custom_a_param, custom_b_param=NEW.custom_b_param, efficiency=NEW.efficiency
            WHERE node_id=OLD.node_id;

        ELSIF v_epatype = 'orifice' THEN
            UPDATE inp_orifice
            SET ori_type=NEW.ori_type, offsetval=NEW.offsetval, cd=NEW.cd, orate=NEW.orate, flap=NEW.flap, shape=NEW.shape, geom1=NEW.geom1,
            geom2=NEW.geom2, geom3=NEW.geom3, geom4=NEW.geom4
            WHERE arc_id=OLD.arc_id;

        ELSIF v_epatype = 'weir' THEN
            UPDATE inp_weir
            SET weir_type=NEW.weir_type, offsetval=NEW.offsetval, cd=NEW.cd, ec=NEW.ec, cd2=NEW.cd2, flap=NEW.flap, geom1=NEW.geom1,
            geom2=NEW.geom2, geom3=NEW.geom3, geom4=NEW.geom4, surcharge=NEW.surcharge, road_width=NEW.road_width, road_surf=NEW.road_surf, coef_curve=NEW.coef_curve
            WHERE arc_id=OLD.arc_id;

        ELSIF v_epatype = 'outlet' THEN
            UPDATE inp_outlet
            SET outlet_type=NEW.outlet_type, offsetval=NEW.offsetval, curve_id=NEW.curve_id, cd1=NEW.cd1,  cd2=NEW.cd2, flap=NEW.flap
            WHERE arc_id=OLD.arc_id;

        ELSIF v_epatype = 'inlet' THEN
            UPDATE inp_inlet
            SET y0=NEW.y0, ysur=NEW.ysur, apond=NEW.apond, inlet_type=NEW.inlet_type, outlet_type=NEW.outlet_type, gully_method=NEW.gully_method, custom_top_elev=NEW.custom_top_elev, custom_depth=NEW.custom_depth,
            inlet_length=NEW.inlet_length, inlet_width=NEW.inlet_width, cd1=NEW.cd1, cd2=NEW.cd2, efficiency=NEW.efficiency
            WHERE node_id=OLD.node_id;

        ELSIF v_epatype = 'gully' OR v_epatype = 'pgully' THEN
            UPDATE inp_gully
            SET outlet_type=NEW.outlet_type, custom_top_elev=NEW.custom_top_elev, custom_width=NEW.custom_width,
            custom_length=NEW.custom_length, custom_depth=NEW.custom_depth, gully_method=NEW.gully_method,
            weir_cd=NEW.weir_cd, orifice_cd=NEW.orifice_cd, custom_a_param=NEW.custom_a_param,
            custom_b_param=NEW.custom_b_param, efficiency=NEW.efficiency
            WHERE gully_id=OLD.gully_id;

		ELSIF v_epatype = 'frpump' THEN
            UPDATE inp_frpump SET curve_id=NEW.curve_id, status=NEW.status, startup=NEW.startup, shutoff=NEW.shutoff WHERE element_id=NEW.element_id;
        
        ELSIF v_epatype = 'froutlet' THEN
            UPDATE inp_froutlet SET outlet_type=NEW.outlet_type, offsetval=NEW.offsetval, curve_id=NEW.curve_id, cd1=NEW.cd1, cd2=NEW.cd2, flap=NEW.flap WHERE element_id=NEW.element_id;
        
        ELSIF v_epatype = 'frorifice' THEN
            UPDATE inp_frorifice SET orifice_type=NEW.orifice_type, offsetval=NEW.offsetval, cd=NEW.cd, orate=NEW.orate, flap=NEW.flap, shape=NEW.shape, geom1=NEW.geom1, geom2=NEW.geom2, geom3=NEW.geom3, geom4=NEW.geom4 WHERE element_id=NEW.element_id;
        
        ELSIF v_epatype = 'frweir' THEN
            UPDATE inp_frweir SET weir_type=NEW.weir_type, offsetval=NEW.offsetval, cd=NEW.cd, ec=NEW.ec, cd2=NEW.cd2, flap=NEW.flap, geom1=NEW.geom1, geom2=NEW.geom2, geom3=NEW.geom3, geom4=NEW.geom4, surcharge=NEW.surcharge, road_width=NEW.road_width, road_surf=NEW.road_surf, coef_curve=NEW.coef_curve WHERE element_id=NEW.element_id;
        END IF;

		RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"1032", "function":"3140","parameters":null}}$$);';
        RETURN NEW;

    END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;





/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3226

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_inp_gully()
RETURNS trigger AS
$BODY$
DECLARE
    v_epa_table varchar;
    v_man_table varchar;
    v_sql varchar;
    v_old_arctype varchar;
    v_new_arctype varchar;

BEGIN

    EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
    v_epa_table:= TG_ARGV[0];

    IF TG_OP = 'INSERT' THEN
        EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"1030", "function":"3226","parameters":null}}$$);';
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        -- The geom
        IF (ST_equals (NEW.the_geom, OLD.the_geom)) IS FALSE THEN
            UPDATE gully SET the_geom=NEW.the_geom WHERE gully_id = NEW.gully_id;

            --update top_elev from raster
            IF (SELECT json_extract_path_text(value::json,'activated')::boolean FROM config_param_system WHERE parameter='admin_raster_dem') IS TRUE
            AND (NEW.top_elev IS NULL) AND
            (SELECT upper(value)  FROM config_param_user WHERE parameter = 'edit_update_elevation_from_dem' and cur_user = current_user) = 'TRUE' THEN
					NEW.top_elev = (SELECT ST_Value(rast,1,NEW.the_geom,true) FROM v_raster_dem WHERE id =
					(SELECT id FROM v_raster_dem WHERE st_dwithin (envelope, NEW.the_geom, 1) LIMIT 1));	
            END IF;
        END IF;

        --get default values
        IF (NEW.outlet_type IS NULL) THEN
                NEW.outlet_type := (SELECT "value" FROM config_param_user WHERE "parameter"='epa_gully_outlet_type_vdefault' AND "cur_user"="current_user"() LIMIT 1);
        END IF;

        IF (NEW.gully_method IS NULL) THEN
                NEW.gully_method := (SELECT "value" FROM config_param_user WHERE "parameter"='epa_gully_method_vdefault' AND "cur_user"="current_user"() LIMIT 1);
        END IF;

        IF NEW.weir_cd IS NULL AND NEW.outlet_type='W_0' THEN
                NEW.weir_cd := (SELECT "value" FROM config_param_user WHERE "parameter"='epa_gully_weir_cd_vdefault' AND "cur_user"="current_user"() LIMIT 1);
        END IF;

        IF NEW.orifice_cd IS NULL AND NEW.outlet_type='W_0' THEN
                NEW.orifice_cd := (SELECT "value" FROM config_param_user WHERE "parameter"='epa_gully_orifice_cd_vdefault' AND "cur_user"="current_user"() LIMIT 1);
        END IF;

        IF (NEW.efficiency IS NULL) THEN
                NEW.efficiency := (SELECT "value" FROM config_param_user WHERE "parameter"='epa_gully_efficiency_vdefault' AND "cur_user"="current_user"() LIMIT 1);
        END IF;

        --update inp_gully data
        UPDATE inp_gully
        SET custom_length=NEW.custom_length, efficiency=NEW.efficiency,
        outlet_type=NEW.outlet_type, custom_top_elev=NEW.custom_top_elev, custom_width=NEW.custom_width,
        custom_depth=NEW.custom_depth, gully_method=NEW.gully_method, weir_cd=NEW.weir_cd, orifice_cd=NEW.orifice_cd,
        custom_a_param=NEW.custom_a_param, custom_b_param=NEW.custom_b_param
        WHERE gully_id=NEW.gully_id;


        UPDATE gully
        SET top_elev=NEW.top_elev,
        gully_type=NEW.gully_type, gullycat_id=NEW.gullycat_id, units=NEW.units, groove=NEW.groove, state_type=NEW.state_type,
        annotation=NEW.annotation,arc_id=NEW.arc_id, units_placement=NEW.units_placement, groove_height=NEW.groove_height, groove_length=NEW.groove_length,
        sector_id=NEW.sector_id
        WHERE gully_id=NEW.gully_id;

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"1032", "function":"3226","parameters":null}}$$);';
        RETURN NEW;

    END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

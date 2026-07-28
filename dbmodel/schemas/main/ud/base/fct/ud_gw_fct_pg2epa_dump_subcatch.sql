/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2228

DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_pg2epa_dump_subcatch() ;
CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_fct_pg2epa_dump_subcatch(p_data json) 
RETURNS SETOF character varying AS
$BODY$

/*
EXAMPLE
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "useNetworkGeom":"false"}}$$)
SELECT SCHEMA_NAME.gw_fct_pg2epa_dump_subcatch($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1"}}$$)

-- fid:117

*/


DECLARE
subcatchment_polygon public.geometry;
row_id varchar(16);
v_hydrology_id int4;
index_point integer;
point_aux public.geometry;
v_client_epsg integer;
v_fid integer = 117;
v_message text;

BEGIN

	--  Search path
	SET search_path = "SCHEMA_NAME", public;

	-- get input parameters
	v_client_epsg = (p_data->>'client')::json->>'epsg';

	-- validate QGIS project CRS for INP export (projected CRS required)
	IF v_client_epsg IS NULL OR NOT EXISTS (SELECT 1 FROM spatial_ref_sys WHERE srid = v_client_epsg) THEN
		SELECT error_message INTO v_message FROM sys_message WHERE id = 4370;
		RAISE EXCEPTION '%', v_message;
	END IF;

	IF gw_fct_is_geographic_srid(v_client_epsg) IS TRUE THEN
		SELECT error_message INTO v_message FROM sys_message WHERE id = 4371;
		RAISE EXCEPTION '%', v_message;
	END IF;

	DELETE FROM temp_t_table WHERE fid = v_fid;

	-- Dump node coordinates for every polygon
	FOR row_id, v_hydrology_id IN SELECT subc_id, hydrology_id FROM ve_inp_subcatchment
	LOOP

		-- Get the geom and remain fields
		SELECT INTO subcatchment_polygon the_geom FROM inp_subcatchment WHERE subc_id = row_id AND hydrology_id = v_hydrology_id;

		-- Loop for nodes
		index_point := 1;
		FOR point_aux IN SELECT (ST_dumppoints(subcatchment_polygon)).geom
		LOOP
			-- Insert result into outfile table
			INSERT INTO temp_t_table (fid, text_column) VALUES ( v_fid, format('%s       %s       %s       ', row_id, 
			to_char(ST_X(ST_Transform(point_aux,v_client_epsg)),'99999999.999'), 
			to_char(ST_Y(ST_Transform(point_aux,v_client_epsg)),'99999999.999')) );
		END LOOP;

	END LOOP;

	-- Return the temporal table
	RETURN QUERY SELECT text_column::varchar FROM temp_t_table WHERE cur_user=current_user AND fid = 117;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

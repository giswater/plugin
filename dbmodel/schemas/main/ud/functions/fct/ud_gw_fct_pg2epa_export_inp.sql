/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE:2528

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_utils_csv2pg_export_swmm_inp(character varying);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_utils_csv2pg_export_swmm_inp(character varying, text);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_pg2epa_export_inp(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_pg2epa_main($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1", "useNetworkGeom":"false", "dumpSubcatch":"true"}}$$)
SELECT SCHEMA_NAME.gw_fct_pg2epa_export_inp($${"client":{"device":4, "infoType":1, "lang":"ES", "epsg":SRID_VALUE}, "data":{"resultId":"test1"}}$$)

--fid:141
*/

DECLARE
rec_table record;
column_number integer;
id_last integer;
num_col_rec record;
num_column text;
v_result varchar;
v_fid integer = 141;
v_return json;
v_client_epsg integer;
v_exportmode integer;
v_message text;


BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;

	-- get input parameters
	v_result = (p_data->>'data')::json->>'resultId';
	v_client_epsg = (p_data->>'client')::json->>'epsg';

	-- validate QGIS project CRS for INP export (projected CRS required)
	IF v_client_epsg IS NULL OR NOT EXISTS (SELECT 1 FROM spatial_ref_sys WHERE srid = v_client_epsg) THEN
		SELECT error_message INTO v_message FROM sys_message WHERE id = 4370;
		RETURN ('{"status":"Failed","message":{"level":1, "text":"'||v_message||'"}}')::json;
	END IF;

	IF gw_fct_is_geographic_srid(v_client_epsg) IS TRUE THEN
		SELECT error_message INTO v_message FROM sys_message WHERE id = 4371;
		RETURN ('{"status":"Failed","message":{"level":1, "text":"'||v_message||'"}}')::json;
	END IF;

	-- get user parameters
	v_exportmode = (SELECT value FROM config_param_user WHERE parameter = 'inp_options_networkmode' and cur_user = current_user);
	IF v_exportmode IS NULL THEN v_exportmode = 1; END IF;

	--Delete previous
	TRUNCATE temp_t_csv;

	-- build header of inp file
	INSERT INTO temp_t_csv (source, csv1,fid) VALUES ('header','[TITLE]',v_fid);
	INSERT INTO temp_t_csv (source, csv1,fid) VALUES ('header',concat(';Created by Giswater'),v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Giswater version: ',(SELECT giswater FROM sys_version ORDER BY id DESC LIMIT 1), v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Project name: ',(SELECT title FROM inp_project_id where author=current_user), v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Result name: ',v_result, v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Export mode: ',
	(SELECT idval FROM config_param_user, inp_typevalue WHERE id = value AND typevalue = 'inp_options_networkmode' and cur_user = current_user and parameter = 'inp_options_networkmode')
	, v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Hydrology scenario: ',(SELECT name
	FROM config_param_user JOIN cat_hydrology ON value = hydrology_id::text WHERE parameter = 'inp_options_hydrology_current' AND cur_user = current_user), v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';DWF scenario: ',(SELECT idval
	FROM config_param_user JOIN cat_dwf c ON value = c.id::text WHERE parameter = 'inp_options_dwfscenario_current' AND cur_user = current_user), v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Default values: ',(SELECT value::json->>'status'
	FROM config_param_user WHERE parameter = 'inp_options_vdefault' AND cur_user = current_user), v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Advanced settings: ',(SELECT value::json->>'status'
	FROM config_param_user WHERE parameter = 'inp_options_advancedsettings' AND cur_user = current_user), v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';Datetime: ',left((date_trunc('second'::text, now()))::text, 19),v_fid);
	INSERT INTO temp_t_csv (source, csv1,csv2,fid) VALUES ('header',';User: ',current_user, v_fid);



	CREATE OR REPLACE TEMP VIEW vi_t_adjustments AS
	 SELECT a.adj_type AS parameter,
	    a.subc_id,
	    a.monthly_adj
	   FROM ( SELECT 1 AS "order",
		    inp_adjustments.adj_type,
		    NULL::character varying AS subc_id,
		    concat(inp_adjustments.value_1, ' ', inp_adjustments.value_2, ' ', inp_adjustments.value_3, ' ', inp_adjustments.value_4, ' ', inp_adjustments.value_5, ' ', inp_adjustments.value_6, ' ', inp_adjustments.value_7, ' ', inp_adjustments.value_8, ' ', inp_adjustments.value_9, ' ', inp_adjustments.value_10, ' ', inp_adjustments.value_11, ' ', inp_adjustments.value_12) AS monthly_adj
		   FROM inp_adjustments
		UNION
		 SELECT 2,
		    'N-PERV'::character varying AS parameter,
		    inp_subcatchment.subc_id,
		    inp_subcatchment.nperv_pattern_id AS montly_adjunstment
		   FROM inp_subcatchment
		  WHERE inp_subcatchment.nperv_pattern_id IS NOT NULL
		UNION
		 SELECT 2,
		    'DSTORE'::character varying,
		    inp_subcatchment.subc_id,
		    inp_subcatchment.dstore_pattern_id AS montly_adjunstment
		   FROM inp_subcatchment
		  WHERE inp_subcatchment.dstore_pattern_id IS NOT NULL
		UNION
		 SELECT 2,
		    'INFIL'::character varying,
		    inp_subcatchment.subc_id,
		    inp_subcatchment.infil_pattern_id AS montly_adjunstment
		   FROM inp_subcatchment
		  WHERE inp_subcatchment.infil_pattern_id IS NOT NULL) a;

	CREATE OR REPLACE TEMP VIEW vi_t_aquifers AS
	 SELECT inp_aquifer.aquif_id,
	    inp_aquifer.por,
	    inp_aquifer.wp,
	    inp_aquifer.fc,
	    inp_aquifer.k,
	    inp_aquifer.ks,
	    inp_aquifer.ps,
	    inp_aquifer.uef,
	    inp_aquifer.led,
	    inp_aquifer.gwr,
	    inp_aquifer.be,
	    inp_aquifer.wte,
	    inp_aquifer.umc,
	    inp_aquifer.pattern_id
	   FROM inp_aquifer
	  ORDER BY inp_aquifer.aquif_id;

	CREATE OR REPLACE TEMP VIEW vi_t_buildup AS
	 SELECT inp_buildup.landus_id,
	    inp_buildup.poll_id,
	    inp_typevalue.id AS funcb_type,
	    inp_buildup.c1,
	    inp_buildup.c2,
	    inp_buildup.c3,
	    inp_buildup.perunit
	   FROM inp_buildup
	     LEFT JOIN inp_typevalue ON inp_typevalue.id::text = inp_buildup.funcb_type::text
	  WHERE inp_typevalue.typevalue::text = 'inp_value_buildup'::text;


	CREATE OR REPLACE TEMP VIEW vi_t_conduits AS
	 SELECT t.arc_id,
	    t.node_1,
	    t.node_2,
	    t.length,
	    t.n,
	    t.elevmax1 AS z1,
	    t.elevmax2 AS z2,
	    t.q0::numeric(12,4) AS q0,
	    t.qmax::numeric(12,4) AS qmax,
	    concat(';', t.sector_id, ' ', t.arccat_id, ' ', t.age) AS other
	   FROM temp_t_arc t
	     JOIN inp_conduit ON t.arc_id = inp_conduit.arc_id::text
	UNION
	 SELECT t.arc_id,
	    t.node_1,
	    t.node_2,
	    t.length,
	    t.n,
	    t.elevmax1 AS z1,
	    t.elevmax2 AS z2,
	    t.q0::numeric(12,4) AS q0,
	    t.qmax::numeric(12,4) AS qmax,
	    concat(';', t.sector_id, ' ', t.arccat_id) AS other
	   FROM temp_t_arc t
	     JOIN inp_conduit ON t.arcparent::text = inp_conduit.arc_id::text;


	CREATE OR REPLACE TEMP VIEW vi_t_controls AS
	 SELECT c.text
	   FROM ( SELECT inp_controls.id,
		    inp_controls.text
		   FROM selector_sector,
		    inp_controls
		  WHERE selector_sector.sector_id = inp_controls.sector_id AND selector_sector.cur_user = "current_user"()::text AND inp_controls.active IS NOT FALSE
		UNION
		 SELECT d.id,
		    d.text
		   FROM selector_sector s,
		    ve_inp_dscenario_controls d
		  WHERE s.sector_id = d.sector_id AND s.cur_user = "current_user"()::text AND d.active IS NOT FALSE
	  ORDER BY 1) c
	  ORDER BY c.id;

	 CREATE OR REPLACE TEMP VIEW vi_t_coordinates AS
	 SELECT node_id,
	    NULL::numeric(16,3) AS xcoord,
	    NULL::numeric(16,3) AS ycoord,
	    the_geom
	   FROM temp_t_node;


	CREATE OR REPLACE TEMP VIEW vi_t_coverages AS
	 SELECT ve_inp_subcatchment.subc_id,
	    inp_coverage.landus_id,
	    inp_coverage.percent
	   FROM inp_coverage
	     JOIN ve_inp_subcatchment ON inp_coverage.subc_id::text = ve_inp_subcatchment.subc_id::text
	     LEFT JOIN ( SELECT DISTINCT ON (a.subc_id) a.subc_id,
		    ve_node.node_id
		   FROM ( SELECT unnest(inp_subcatchment.outlet_id::text[]) AS node_array,
			    inp_subcatchment.subc_id,
			    inp_subcatchment.outlet_id,
			    inp_subcatchment.rg_id,
			    inp_subcatchment.area,
			    inp_subcatchment.imperv,
			    inp_subcatchment.width,
			    inp_subcatchment.slope,
			    inp_subcatchment.clength,
			    inp_subcatchment.snow_id,
			    inp_subcatchment.nimp,
			    inp_subcatchment.nperv,
			    inp_subcatchment.simp,
			    inp_subcatchment.sperv,
			    inp_subcatchment.zero,
			    inp_subcatchment.routeto,
			    inp_subcatchment.rted,
			    inp_subcatchment.maxrate,
			    inp_subcatchment.minrate,
			    inp_subcatchment.decay,
			    inp_subcatchment.drytime,
			    inp_subcatchment.maxinfil,
			    inp_subcatchment.suction,
			    inp_subcatchment.conduct,
			    inp_subcatchment.initdef,
			    inp_subcatchment.curveno,
			    inp_subcatchment.conduct_2,
			    inp_subcatchment.drytime_2,
			    inp_subcatchment.sector_id,
			    inp_subcatchment.hydrology_id,
			    inp_subcatchment.the_geom,
			    inp_subcatchment.descript
			   FROM inp_subcatchment
			  WHERE "left"(inp_subcatchment.outlet_id::text, 1) = '{'::text) a
		     JOIN ve_node ON ve_node.node_id::text = a.node_array) b ON ve_inp_subcatchment.subc_id::text = b.subc_id::text;


	 CREATE OR REPLACE TEMP VIEW vi_t_dividers AS
	 SELECT temp_t_node.node_id,
	    temp_t_node.elev,
	    temp_t_node.addparam::json ->> 'arc_id'::text AS arc_id,
	    temp_t_node.addparam::json ->> 'divider_type'::text AS divider_type,
	    temp_t_node.addparam::json ->> 'qmin'::text AS other1,
	    temp_t_node.y0 AS other2,
	    temp_t_node.ysur AS other3,
	    temp_t_node.apond AS other4,
	    NULL::double precision AS other5,
	    NULL::double precision AS other6
	   FROM temp_t_node
	  WHERE temp_t_node.epa_type::text = 'DIVIDER'::text AND (temp_t_node.addparam::json ->> 'divider_type'::text) = 'CUTOFF'::text
	UNION
	 SELECT temp_t_node.node_id,
	    temp_t_node.elev,
	    temp_t_node.addparam::json ->> 'arc_id'::text AS arc_id,
	    temp_t_node.addparam::json ->> 'divider_type'::text AS divider_type,
	    temp_t_node.y0::text AS other1,
	    temp_t_node.ysur AS other2,
	    temp_t_node.apond AS other3,
	    NULL::numeric AS other4,
	    NULL::double precision AS other5,
	    NULL::double precision AS other6
	   FROM temp_t_node
	  WHERE temp_t_node.epa_type::text = 'DIVIDER'::text AND (temp_t_node.addparam::json ->> 'divider_type'::text) = 'OVERFLOW'::text
	UNION
	 SELECT temp_t_node.node_id,
	    temp_t_node.elev,
	    temp_t_node.addparam::json ->> 'arc_id'::text AS arc_id,
	    temp_t_node.addparam::json ->> 'divider_type'::text AS divider_type,
	    temp_t_node.addparam::json ->> 'curve_id'::text AS other1,
	    temp_t_node.y0 AS other2,
	    temp_t_node.ysur AS other3,
	    temp_t_node.apond AS other4,
	    NULL::double precision AS other5,
	    NULL::double precision AS other6
	   FROM temp_t_node
	  WHERE temp_t_node.epa_type::text = 'DIVIDER'::text AND (temp_t_node.addparam::json ->> 'divider_type'::text) = 'TABULAR'::text
	UNION
	 SELECT temp_t_node.node_id,
	    temp_t_node.elev,
	    temp_t_node.addparam::json ->> 'arc_id'::text AS arc_id,
	    temp_t_node.addparam::json ->> 'divider_type'::text AS divider_type,
	    temp_t_node.addparam::json ->> 'qmin'::text AS other1,
	    (temp_t_node.addparam::json ->> 'ht'::text)::numeric AS other2,
	    (temp_t_node.addparam::json ->> 'cd'::text)::numeric AS other3,
	    temp_t_node.y0 AS other4,
	    temp_t_node.ysur AS other5,
	    temp_t_node.apond AS other6
	   FROM temp_t_node
	  WHERE temp_t_node.epa_type::text = 'DIVIDER'::text AND (temp_t_node.addparam::json ->> 'divider_type'::text) = 'WEIR'::text;


	CREATE OR REPLACE TEMP VIEW vi_t_dwf AS
	 SELECT temp_t_node.node_id,
	    'FLOW'::text AS type_dwf,
	    inp_dwf.value,
	    inp_dwf.pat1,
	    inp_dwf.pat2,
	    inp_dwf.pat3,
	    inp_dwf.pat4
	   FROM selector_inp_result,
	    temp_t_node
	     JOIN inp_dwf ON inp_dwf.node_id::text = temp_t_node.node_id::text
	  WHERE temp_t_node.result_id::text = selector_inp_result.result_id::text AND selector_inp_result.cur_user = "current_user"()::text AND inp_dwf.dwfscenario_id = (( SELECT config_param_user.value::integer AS value
		   FROM config_param_user
		  WHERE config_param_user.parameter::text = 'inp_options_dwfscenario_current'::text AND config_param_user.cur_user::text = CURRENT_USER))
	UNION
	 SELECT temp_t_node.node_id,
	    inp_dwf_pol_x_node.poll_id AS type_dwf,
	    inp_dwf_pol_x_node.value,
	    inp_dwf_pol_x_node.pat1,
	    inp_dwf_pol_x_node.pat2,
	    inp_dwf_pol_x_node.pat3,
	    inp_dwf_pol_x_node.pat4
	   FROM selector_inp_result,
	    temp_t_node
	     JOIN inp_dwf_pol_x_node ON inp_dwf_pol_x_node.node_id::text = temp_t_node.node_id::text
	  WHERE temp_t_node.result_id::text = selector_inp_result.result_id::text AND selector_inp_result.cur_user = "current_user"()::text AND inp_dwf_pol_x_node.dwfscenario_id = (( SELECT config_param_user.value::integer AS value
		   FROM config_param_user
		  WHERE config_param_user.parameter::text = 'inp_options_dwfscenario_current'::text AND config_param_user.cur_user::text = CURRENT_USER));



	CREATE OR REPLACE TEMP VIEW vi_t_evaporation AS
	 SELECT inp_evaporation.evap_type,
	    inp_evaporation.value
	   FROM inp_evaporation;



	CREATE OR REPLACE TEMP VIEW vi_t_files AS
	 SELECT inp_files.actio_type,
	    inp_files.file_type,
	    inp_files.fname
	   FROM inp_files
	  WHERE inp_files.active IS TRUE;


	CREATE OR REPLACE TEMP VIEW vi_t_groundwater AS
	 SELECT inp_groundwater.subc_id,
	    inp_groundwater.aquif_id,
	    inp_groundwater.node_id,
	    inp_groundwater.surfel,
	    inp_groundwater.a1,
	    inp_groundwater.b1,
	    inp_groundwater.a2,
	    inp_groundwater.b2,
	    inp_groundwater.a3,
	    inp_groundwater.tw,
	    inp_groundwater.h
	   FROM ve_inp_subcatchment
	     JOIN inp_groundwater ON inp_groundwater.subc_id::text = ve_inp_subcatchment.subc_id::text
	     LEFT JOIN ( SELECT DISTINCT ON (a.subc_id) a.subc_id,
		    ve_node.node_id
		   FROM ( SELECT unnest(inp_subcatchment.outlet_id::text[]) AS node_array,
			    inp_subcatchment.subc_id,
			    inp_subcatchment.outlet_id,
			    inp_subcatchment.rg_id,
			    inp_subcatchment.area,
			    inp_subcatchment.imperv,
			    inp_subcatchment.width,
			    inp_subcatchment.slope,
			    inp_subcatchment.clength,
			    inp_subcatchment.snow_id,
			    inp_subcatchment.nimp,
			    inp_subcatchment.nperv,
			    inp_subcatchment.simp,
			    inp_subcatchment.sperv,
			    inp_subcatchment.zero,
			    inp_subcatchment.routeto,
			    inp_subcatchment.rted,
			    inp_subcatchment.maxrate,
			    inp_subcatchment.minrate,
			    inp_subcatchment.decay,
			    inp_subcatchment.drytime,
			    inp_subcatchment.maxinfil,
			    inp_subcatchment.suction,
			    inp_subcatchment.conduct,
			    inp_subcatchment.initdef,
			    inp_subcatchment.curveno,
			    inp_subcatchment.conduct_2,
			    inp_subcatchment.drytime_2,
			    inp_subcatchment.sector_id,
			    inp_subcatchment.hydrology_id,
			    inp_subcatchment.the_geom,
			    inp_subcatchment.descript
			   FROM inp_subcatchment
			  WHERE "left"(inp_subcatchment.outlet_id::text, 1) = '{'::text) a
		     JOIN ve_node ON ve_node.node_id::text = a.node_array) b ON ve_inp_subcatchment.subc_id::text = b.subc_id::text;


	CREATE OR REPLACE TEMP VIEW vi_t_gully AS
	 SELECT temp_t_gully.gully_id as code,
	    temp_t_gully.outlet_type,
	    COALESCE(temp_t_gully.node_id::text, '-9999'::text) AS outlet_node,
	    st_x(temp_t_gully.the_geom)::numeric(12,3) AS xcoord,
	    st_y(temp_t_gully.the_geom)::numeric(12,3) AS ycoord,
	    COALESCE(temp_t_gully.top_elev::numeric(12,3), '-9999'::integer::numeric) AS zcoord,
	    temp_t_gully.width::numeric(12,3) AS width,
	    temp_t_gully.length::numeric(12,3) AS length,
	    COALESCE(temp_t_gully.depth::numeric(12,3), '-9999'::integer::numeric) AS depth,
	    temp_t_gully.method,
	    COALESCE(temp_t_gully.weir_cd::numeric(12,3), '-9999'::integer::numeric) AS weir_cd,
	    COALESCE(temp_t_gully.orifice_cd::numeric(12,3), '-9999'::integer::numeric) AS orifice_cd,
	    COALESCE(temp_t_gully.a_param::numeric(12,3), '-9999'::integer::numeric) AS a_param,
	    COALESCE(temp_t_gully.b_param::numeric(12,3), '-9999'::integer::numeric) AS b_param,
		COALESCE(temp_t_gully.efficiency, cat_gully.efficiency) AS efficiency
	   FROM temp_t_gully
	     LEFT JOIN cat_gully ON cat_gully.id = temp_t_gully.gullycat_id;


	CREATE OR REPLACE TEMP VIEW vi_t_gwf AS
	 SELECT inp_groundwater.subc_id,
	    ('LATERAL'::text || ' '::text) || inp_groundwater.fl_eq_lat::text AS fl_eq_lat,
	    ('DEEP'::text || ' '::text) || inp_groundwater.fl_eq_lat::text AS fl_eq_deep
	   FROM ve_inp_subcatchment
	     JOIN inp_groundwater ON inp_groundwater.subc_id::text = ve_inp_subcatchment.subc_id::text;


	CREATE OR REPLACE TEMP VIEW vi_t_hydrographs AS
	 SELECT inp_hydrograph_value.text
	   FROM inp_hydrograph_value;



	CREATE OR REPLACE TEMP VIEW vi_t_infiltration  AS
	 SELECT ve_inp_subcatchment.subc_id,
	    ve_inp_subcatchment.curveno AS other1,
	    ve_inp_subcatchment.conduct_2 AS other2,
	    ve_inp_subcatchment.drytime_2 AS other3,
	    NULL::numeric AS other4,
	    NULL::double precision AS other5
	   FROM ve_inp_subcatchment
	     JOIN cat_hydrology ON cat_hydrology.hydrology_id = ve_inp_subcatchment.hydrology_id
	     JOIN ( SELECT a.subc_id,
		    a.outlet_id
		   FROM ( SELECT unnest(inp_subcatchment.outlet_id::character varying[]) AS outlet_id,
			    inp_subcatchment.subc_id
			   FROM inp_subcatchment
			     JOIN temp_node ON inp_subcatchment.outlet_id::text = temp_node.node_id::text
			  WHERE "left"(inp_subcatchment.outlet_id::text, 1) = '{'::text
			UNION
			 SELECT inp_subcatchment.outlet_id,
			    inp_subcatchment.subc_id
			   FROM inp_subcatchment
			  WHERE "left"(inp_subcatchment.outlet_id::text, 1) <> '{'::text) a) b USING (outlet_id)
	  WHERE cat_hydrology.infiltration::text = 'CURVE_NUMBER'::text
	UNION
	 SELECT ve_inp_subcatchment.subc_id,
	    ve_inp_subcatchment.suction AS other1,
	    ve_inp_subcatchment.conduct AS other2,
	    ve_inp_subcatchment.initdef AS other3,
	    NULL::integer AS other4,
	    NULL::double precision AS other5
	   FROM ve_inp_subcatchment
	     JOIN cat_hydrology ON cat_hydrology.hydrology_id = ve_inp_subcatchment.hydrology_id
	     JOIN ( SELECT a.subc_id,
		    a.outlet_id
		   FROM ( SELECT unnest(inp_subcatchment.outlet_id::character varying[]) AS outlet_id,
			    inp_subcatchment.subc_id
			   FROM inp_subcatchment
			     JOIN temp_node ON inp_subcatchment.outlet_id::text = temp_node.node_id::text
			  WHERE "left"(inp_subcatchment.outlet_id::text, 1) = '{'::text
			UNION
			 SELECT inp_subcatchment.outlet_id,
			    inp_subcatchment.subc_id
			   FROM inp_subcatchment
			  WHERE "left"(inp_subcatchment.outlet_id::text, 1) <> '{'::text) a) b USING (outlet_id)
	  WHERE cat_hydrology.infiltration::text = 'GREEN_AMPT'::text
	UNION
	 SELECT ve_inp_subcatchment.subc_id,
	    ve_inp_subcatchment.curveno AS other1,
	    ve_inp_subcatchment.conduct_2 AS other2,
	    ve_inp_subcatchment.drytime_2 AS other3,
	    NULL::integer AS other4,
	    NULL::double precision AS other5
	   FROM ve_inp_subcatchment
	     JOIN cat_hydrology ON cat_hydrology.hydrology_id = ve_inp_subcatchment.hydrology_id
	     JOIN ( SELECT a.subc_id,
		    a.outlet_id
		   FROM ( SELECT unnest(inp_subcatchment.outlet_id::character varying[]) AS outlet_id,
			    inp_subcatchment.subc_id
			   FROM inp_subcatchment
			     JOIN temp_node ON inp_subcatchment.outlet_id::text = temp_node.node_id::text
			  WHERE "left"(inp_subcatchment.outlet_id::text, 1) = '{'::text
			UNION
			 SELECT inp_subcatchment.outlet_id,
			    inp_subcatchment.subc_id
			   FROM inp_subcatchment
			  WHERE "left"(inp_subcatchment.outlet_id::text, 1) <> '{'::text) a) b USING (outlet_id)
	  WHERE cat_hydrology.infiltration::text = ANY (ARRAY['MODIFIED_HORTON'::text, 'HORTON'::text]);


	CREATE OR REPLACE TEMP VIEW vi_t_inflows AS
	 SELECT temp_t_node_other.node_id,
	    temp_t_node_other.type,
	    temp_t_node_other.timser_id,
	    'FLOW'::text AS format,
	    1::numeric(12,4) AS mfactor,
		1::numeric(12,4) AS sfactor,
	    temp_t_node_other.base,
	    temp_t_node_other.pattern_id
	   FROM temp_t_node_other
	  WHERE temp_t_node_other.type::text = 'FLOW'::text AND active
	UNION
	 SELECT temp_t_node_other.node_id,
	    temp_t_node_other.poll_id AS type,
	    temp_t_node_other.timser_id,
	    temp_t_node_other.other AS format,
	    temp_t_node_other.mfactor,
	    temp_t_node_other.sfactor,
	    temp_t_node_other.base,
	    temp_t_node_other.pattern_id
	   FROM temp_t_node_other
	  WHERE temp_t_node_other.type::text = 'POLLUTANT'::text  AND active
	  ORDER BY 1;


	CREATE OR REPLACE TEMP VIEW vi_t_junctions AS
	 SELECT temp_t_node.node_id,
	    temp_t_node.elev,
	    temp_t_node.ymax,
	    temp_t_node.y0,
	    temp_t_node.ysur,
	    temp_t_node.apond,
	    concat(';', temp_t_node.sector_id, ' ', temp_t_node.node_type) AS other
	   FROM temp_t_node
	  WHERE temp_t_node.epa_type::text = ANY (ARRAY['JUNCTION'::text, 'NETGULLY'::text, 'INLET'::text, 'UNDEFINED'::text]);

	CREATE OR REPLACE TEMP VIEW vi_t_labels AS
	 SELECT inp_label.xcoord,
	    inp_label.ycoord,
	    inp_label.label,
	    inp_label.anchor,
	    inp_label.font,
	    inp_label.size,
	    inp_label.bold,
	    inp_label.italic
	   FROM inp_label
	  ORDER BY inp_label.label;

	CREATE OR REPLACE TEMP VIEW vi_t_landuses AS
	 SELECT inp_landuses.landus_id,
	    inp_landuses.sweepint,
	    inp_landuses.availab,
	    inp_landuses.lastsweep
	   FROM inp_landuses;


	CREATE OR REPLACE TEMP VIEW vi_t_lid_controls AS
	 SELECT a.lidco_id,
	    a.lidco_type,
	    a.other1,
	    a.other2,
	    a.other3,
	    a.other4,
	    a.other5,
	    a.other6,
	    a.other7
	   FROM ( SELECT 0 AS id,
		    inp_lid.lidco_id,
		    inp_lid.lidco_type,
		    NULL::numeric AS other1,
		    NULL::numeric AS other2,
		    NULL::numeric AS other3,
		    NULL::numeric AS other4,
		    NULL::text AS other5,
		    NULL::text AS other6,
		    NULL::text AS other7
		   FROM inp_lid
 		   JOIN (select distinct (lidco_id) from ve_inp_dscenario_lids)a USING (lidco_id)
		  WHERE inp_lid.active
		UNION
		 SELECT inp_lid_value.id,
		    inp_lid_value.lidco_id,
		    inp_typevalue.id AS lidco_type,
		    CASE WHEN inp_lid_value.value_2 = 0 THEN 0 ELSE inp_lid_value.value_2 END AS other1,
		    CASE WHEN inp_lid_value.value_3 = 0 THEN 0 ELSE inp_lid_value.value_3 END AS other2,
		    CASE WHEN inp_lid_value.value_4 = 0 THEN 0 ELSE inp_lid_value.value_4 END AS other3,
		    CASE WHEN inp_lid_value.value_5 = 0 THEN 0 ELSE inp_lid_value.value_5 END AS other4,
		    CASE 
			    WHEN inp_lid_value.value_6 ~ '^[0-9]+(\.[0-9]+)?$' AND inp_lid_value.value_6::NUMERIC = 0 THEN '0'
			    ELSE inp_lid_value.value_6::TEXT
			END AS other5,
			CASE 
			    WHEN inp_lid_value.value_7 ~ '^[0-9]+(\.[0-9]+)?$' AND inp_lid_value.value_7::NUMERIC = 0 THEN '0'
			    ELSE inp_lid_value.value_7::TEXT
			END AS other6,
			CASE 
			    WHEN inp_lid_value.value_8 ~ '^[0-9]+(\.[0-9]+)?$' AND inp_lid_value.value_8::NUMERIC = 0 THEN '0'
			    ELSE inp_lid_value.value_8::TEXT
			END AS other7
		   FROM inp_lid_value
		     JOIN inp_lid USING (lidco_id)
		     JOIN (select distinct (lidco_id) from ve_inp_dscenario_lids)a USING (lidco_id)
		     LEFT JOIN inp_typevalue ON inp_typevalue.id::text = inp_lid_value.lidlayer::text
		  WHERE inp_lid.active AND inp_typevalue.typevalue::text = 'inp_value_lidlayer'::text) a
	  ORDER BY a.lidco_id, a.id;


	 CREATE OR REPLACE TEMP VIEW vi_t_lid_usage AS
	 SELECT temp_t_lid_usage.subc_id,
	    temp_t_lid_usage.lidco_id,
	    temp_t_lid_usage.numelem::integer AS numelem,
	    temp_t_lid_usage.area,
	    temp_t_lid_usage.width,
	    temp_t_lid_usage.initsat,
	    temp_t_lid_usage.fromimp,
	    temp_t_lid_usage.toperv::integer AS toperv,
	    temp_t_lid_usage.rptfile
	   FROM ve_inp_subcatchment
	     JOIN temp_t_lid_usage ON temp_t_lid_usage.subc_id::text = ve_inp_subcatchment.subc_id::text;

	CREATE OR REPLACE TEMP VIEW vi_t_loadings  AS
	 SELECT inp_loadings.subc_id,
	    inp_loadings.poll_id,
	    inp_loadings.ibuildup
	   FROM ve_inp_subcatchment
	     JOIN inp_loadings ON inp_loadings.subc_id::text = ve_inp_subcatchment.subc_id::text;


	 CREATE OR REPLACE TEMP VIEW vi_t_losses AS
	 SELECT temp_t_arc.arc_id,
		CASE
		    WHEN temp_t_arc.kentry IS NOT NULL THEN temp_t_arc.kentry
		    ELSE 0::numeric
		END AS kentry,
		CASE
		    WHEN temp_t_arc.kexit IS NOT NULL THEN temp_t_arc.kexit
		    ELSE 0::numeric
		END AS kexit,
		CASE
		    WHEN temp_t_arc.kavg IS NOT NULL THEN temp_t_arc.kavg
		    ELSE 0::numeric
		END AS kavg,
		CASE
		    WHEN temp_t_arc.flap IS NOT NULL THEN temp_t_arc.flap
		    ELSE 'NO'::character varying
		END AS flap,
	    temp_t_arc.seepage
	   FROM temp_t_arc
	  WHERE temp_t_arc.kentry > 0::numeric OR temp_t_arc.kexit > 0::numeric OR temp_t_arc.kavg > 0::numeric OR temp_t_arc.flap::text = 'YES'::text OR temp_t_arc.seepage IS NOT NULL;


	CREATE OR REPLACE TEMP VIEW vi_t_map  AS
	 SELECT inp_mapdim.type_dim,
	    concat(inp_mapdim.x1, ' ', inp_mapdim.y1, ' ', inp_mapdim.x2, ' ', inp_mapdim.y2) AS other_val
	   FROM inp_mapdim
	UNION
	 SELECT inp_typevalue.id AS type_dim,
	    inp_mapunits.map_type AS other_val
	   FROM inp_mapunits
	     LEFT JOIN inp_typevalue ON inp_typevalue.id::text = inp_mapunits.type_units::text
	  WHERE inp_typevalue.typevalue::text = 'inp_value_mapunits'::text;


	CREATE OR REPLACE TEMP VIEW vi_t_options  AS
	 SELECT a.parameter,
	    a.value
	   FROM ( SELECT a_1.idval AS parameter,
		    b.value,
			CASE
			    WHEN a_1.layoutname ~~ '%general_1%'::text THEN '1'::text
			    WHEN a_1.layoutname ~~ '%hydraulics_1%'::text THEN '2'::text
			    WHEN a_1.layoutname ~~ '%hydraulics_2%'::text THEN '3'::text
			    WHEN a_1.layoutname ~~ '%date_1%'::text THEN '3'::text
			    WHEN a_1.layoutname ~~ '%date_2%'::text THEN '4'::text
			    WHEN a_1.layoutname ~~ '%general_2%'::text THEN '5'::text
			    ELSE NULL::text
			END AS layoutname,
		    a_1.layoutorder
		   FROM sys_param_user a_1
		     JOIN config_param_user b ON a_1.id = b.parameter::text
		  WHERE (a_1.layoutname = ANY (ARRAY['lyt_general_1'::text, 'lyt_general_2'::text, 'lyt_hydraulics_1'::text, 'lyt_hydraulics_2'::text, 'lyt_date_1'::text, 'lyt_date_2'::text])) AND b.cur_user::name = "current_user"() AND b.value IS NOT NULL AND a_1.idval IS NOT NULL
		UNION
		 SELECT 'INFILTRATION'::text AS parameter,
		    cat_hydrology.infiltration AS value,
		    '1'::text AS text,
		    2
		   FROM config_param_user,
		    cat_hydrology
		  WHERE config_param_user.parameter::text = 'inp_options_hydrology_current'::text AND config_param_user.cur_user::text = "current_user"()::text) a
	  ORDER BY a.layoutname, a.layoutorder;


	CREATE OR REPLACE TEMP VIEW vi_t_orifices AS
	 SELECT temp_t_arc.arc_id,
	    temp_t_arc.node_1,
	    temp_t_arc.node_2,
	    f.ori_type,
	    f.offsetval,
	    f.cd,
	    f.flap,
	    f.orate
	   FROM temp_t_arc_flowregulator f
	     JOIN temp_t_arc ON f.arc_id::text = temp_t_arc.arc_id
	  WHERE f.type::text = 'ORIFICE'::text;


	CREATE OR REPLACE TEMP VIEW vi_t_outfalls AS
	 SELECT temp_t_node.node_id,
	    temp_t_node.elev,
	    temp_t_node.addparam::json ->> 'outfall_type'::text AS outfall_type,
	    temp_t_node.addparam::json ->> 'gate'::text AS other1,
	    NULL::text AS other2
	   FROM temp_t_node
	  WHERE temp_t_node.epa_type::text = 'OUTFALL'::text AND ((temp_t_node.addparam::json ->> 'outfall_type'::text) = ANY (ARRAY['FREE'::text, 'NORMAL'::text]))
	UNION
	 SELECT temp_t_node.node_id,
	    temp_t_node.elev,
	    temp_t_node.addparam::json ->> 'outfall_type'::text AS outfall_type,
	    temp_t_node.addparam::json ->> 'state'::text AS other1,
	    temp_t_node.addparam::json ->> 'gate'::text AS other2
	   FROM temp_t_node
	  WHERE temp_t_node.epa_type::text = 'OUTFALL'::text AND (temp_t_node.addparam::json ->> 'outfall_type'::text) = 'FIXED'::text
	UNION
	 SELECT temp_t_node.node_id,
	    temp_t_node.elev,
	    temp_t_node.addparam::json ->> 'outfall_type'::text AS outfall_type,
	    temp_t_node.addparam::json ->> 'curve_id'::text AS other1,
	    temp_t_node.addparam::json ->> 'gate'::text AS other2
	   FROM temp_t_node
	  WHERE temp_t_node.epa_type::text = 'OUTFALL'::text AND (temp_t_node.addparam::json ->> 'outfall_type'::text) = 'TIDAL'::text
	UNION
	 SELECT temp_t_node.node_id,
	    temp_t_node.elev,
	    temp_t_node.addparam::json ->> 'outfall_type'::text AS outfall_type,
	    temp_t_node.addparam::json ->> 'timser_id'::text AS other1,
	    temp_t_node.addparam::json ->> 'gate'::text AS other2
	   FROM temp_t_node
	  WHERE temp_t_node.epa_type::text = 'OUTFALL'::text AND (temp_t_node.addparam::json ->> 'outfall_type'::text) = 'TIMESERIES'::text;


	 CREATE OR REPLACE TEMP VIEW vi_t_outlets AS
	 SELECT temp_t_arc.arc_id,
	    temp_t_arc.node_1,
	    temp_t_arc.node_2,
		CASE
		    WHEN f.offsetval IS NULL THEN '*'::text
		    ELSE f.offsetval::text
		END AS offsetval,
	    f.outlet_type,
		CASE
		    WHEN f.curve_id IS NULL THEN f.cd1::text::character varying
		    ELSE f.curve_id
		END AS other1,
	    f.cd2::text AS other2,
	    f.flap::character varying AS other3
	   FROM temp_t_arc_flowregulator f
	     JOIN temp_t_arc ON f.arc_id::text = temp_t_arc.arc_id
	  WHERE f.type::text = 'OUTLET'::text;


	CREATE OR REPLACE TEMP VIEW vi_t_pollutants AS
	 SELECT inp_pollutant.poll_id,
	    inp_pollutant.units_type,
	    inp_pollutant.crain,
	    inp_pollutant.cgw,
	    inp_pollutant.cii,
	    inp_pollutant.kd,
	    inp_pollutant.sflag,
	    inp_pollutant.copoll_id,
	    inp_pollutant.cofract,
	    inp_pollutant.cdwf,
	    inp_pollutant.cinit
	   FROM inp_pollutant
	  ORDER BY inp_pollutant.poll_id;


	CREATE OR REPLACE TEMP VIEW vi_t_polygons AS
	 SELECT temp_t_table.text_column
	   FROM temp_t_table
	  WHERE temp_t_table.fid = 117;


	CREATE OR REPLACE TEMP VIEW vi_t_pumps AS
	 SELECT temp_t_arc.arc_id,
	    temp_t_arc.node_1,
	    temp_t_arc.node_2,
	    temp_t_arc_flowregulator.curve_id,
	    temp_t_arc_flowregulator.status,
	    temp_t_arc_flowregulator.startup,
	    temp_t_arc_flowregulator.shutoff
	   FROM temp_t_arc_flowregulator
	     JOIN temp_t_arc ON temp_t_arc_flowregulator.arc_id::text = temp_t_arc.arc_id
	  WHERE temp_t_arc_flowregulator.type::text = 'PUMP'::text;

	CREATE OR REPLACE TEMP VIEW vi_t_raingages AS
	 SELECT DISTINCT r.rg_id,
	    r.form_type,
	    r.intvl,
	    r.scf,
	    inp_typevalue.id AS raingage_type,
	    r.timser_id AS other1,
	    NULL::character varying AS other2,
	    NULL::character varying AS other3
	   FROM selector_inp_result s,
	    t_rpt_inp_raingage r
	     LEFT JOIN inp_typevalue ON inp_typevalue.id::text = r.rgage_type::text
	  WHERE inp_typevalue.typevalue::text = 'inp_typevalue_raingage'::text AND r.rgage_type::text = 'TIMESERIES'::text AND s.result_id::text = r.result_id::text AND s.cur_user = CURRENT_USER
	UNION
	 SELECT DISTINCT r.rg_id,
	    r.form_type,
	    r.intvl,
	    r.scf,
	    inp_typevalue.id AS raingage_type,
	    r.fname AS other1,
	    r.sta AS other2,
	    r.units AS other3
	   FROM selector_inp_result s,
	    t_rpt_inp_raingage r
	     LEFT JOIN inp_typevalue ON inp_typevalue.id::text = r.rgage_type::text
	  WHERE inp_typevalue.typevalue::text = 'inp_typevalue_raingage'::text AND r.rgage_type::text = 'FILE'::text AND s.result_id::text = r.result_id::text AND s.cur_user = CURRENT_USER;

	CREATE OR REPLACE TEMP VIEW vi_t_rdii AS
	 SELECT temp_t_node.node_id,
	    inp_rdii.hydro_id,
	    inp_rdii.sewerarea
	   FROM selector_inp_result,
	    temp_t_node
	     JOIN inp_rdii ON inp_rdii.node_id::text = temp_t_node.node_id::text
	  WHERE temp_t_node.result_id::text = selector_inp_result.result_id::text AND selector_inp_result.cur_user = "current_user"()::text;


	CREATE OR REPLACE TEMP VIEW vi_t_report AS
	select * from (
		SELECT a.idval AS parameter,
		b.value
		FROM sys_param_user a
		JOIN config_param_user b ON a.id = b.parameter::text
		WHERE (a.layoutname = ANY (ARRAY['lyt_reports_1'::text, 'lyt_reports_2'::text])) AND b.cur_user::name = "current_user"() AND b.value IS NOT null and parameter not in ('inp_report_nodes_2', 'inp_report_nodes', 'inp_report_links')
		union
		select 'NODES', replace(replace(replace(array_agg(a.node_id)::text,',',' '),'}',''),'{','')  from (select unnest(concat('{',replace(value,' ',','),'}')::integer[]) as node_id
		from config_param_user where parameter = 'inp_report_nodes' and cur_user=current_user)a
		join temp_t_node n on n.node_id = a.node_id::text
		UNION
		select 'NODES', replace(replace(replace(array_agg(a.node_id)::text,',',' '),'}',''),'{','')  from (select unnest(concat('{',replace(value,' ',','),'}')::integer[]) as node_id
		from config_param_user where parameter = 'inp_report_nodes_2' and cur_user=current_user)a
		join temp_t_node n on n.node_id = a.node_id::text
		union
		select 'LINKS', replace(replace(replace(array_agg(a.arc_id)::text,',',' '),'}',''),'{','')  from (select unnest(concat('{',replace(value,' ',','),'}')::integer[]) as arc_id
		from config_param_user where parameter = 'inp_report_link' and cur_user=current_user)a
		join temp_t_arc n on n.arc_id = a.arc_id::text)a
		where value is not null
		ORDER BY 1;


	CREATE OR REPLACE TEMP VIEW vi_t_snowpacks AS
	 SELECT inp_snowpack_value.snow_id,
	    inp_snowpack_value.snow_type,
	    inp_snowpack_value.value_1,
	    inp_snowpack_value.value_2,
	    inp_snowpack_value.value_3,
	    inp_snowpack_value.value_4,
	    inp_snowpack_value.value_5,
	    inp_snowpack_value.value_6,
	    inp_snowpack_value.value_7
	   FROM inp_snowpack_value
	  ORDER BY inp_snowpack_value.id;



	CREATE OR REPLACE TEMP VIEW vi_t_storage AS
	 SELECT temp_t_node.node_id,
	    temp_t_node.elev,
	    temp_t_node.ymax,
	    temp_t_node.y0,
	    temp_t_node.addparam::json ->> 'storage_type'::text AS storage_type,
	    temp_t_node.addparam::json ->> 'a1'::text AS other1,
	    temp_t_node.addparam::json ->> 'a2'::text AS other2,
	    temp_t_node.addparam::json ->> 'a0'::text AS other3,
	    temp_t_node.addparam::json ->> 'fevap'::text AS other4,
	    temp_t_node.addparam::json ->> 'sh'::text AS other5,
	    temp_t_node.addparam::json ->> 'hc'::text AS other6,
	    temp_t_node.addparam::json ->> 'imd'::text AS other7
	   FROM temp_t_node
	  WHERE temp_t_node.epa_type::text = 'STORAGE'::text AND (temp_t_node.addparam::json ->> 'storage_type'::text) = 'FUNCTIONAL'::text
	UNION
	 SELECT temp_t_node.node_id,
	    temp_t_node.elev,
	    temp_t_node.ymax,
	    temp_t_node.y0,
	    temp_t_node.addparam::json ->> 'storage_type'::text AS storage_type,
	    temp_t_node.addparam::json ->> 'curve_id'::text AS other1,
	    temp_t_node.addparam::json ->> 'fevap'::text AS other2,
	    temp_t_node.addparam::json ->> 'sh'::text AS other3,
	    temp_t_node.addparam::json ->> 'hc'::text AS other4,
	    temp_t_node.addparam::json ->> 'imd'::text AS other5,
	    NULL::text AS other7,
	    NULL::text AS other8
	   FROM temp_t_node
	  WHERE temp_t_node.epa_type::text = 'STORAGE'::text AND (temp_t_node.addparam::json ->> 'storage_type'::text) = 'TABULAR'::text;



	CREATE OR REPLACE TEMP VIEW vi_t_subareas AS
	 SELECT DISTINCT ve_inp_subcatchment.subc_id,
	    ve_inp_subcatchment.nimp,
	    ve_inp_subcatchment.nperv,
	    ve_inp_subcatchment.simp,
	    ve_inp_subcatchment.sperv,
	    ve_inp_subcatchment.zero,
	    ve_inp_subcatchment.routeto,
	    ve_inp_subcatchment.rted
	   FROM ve_inp_subcatchment
	     JOIN ( SELECT a.subc_id,
		    a.outlet_id
		   FROM ( SELECT unnest(inp_subcatchment.outlet_id::character varying[]) AS outlet_id,
			    inp_subcatchment.subc_id
			   FROM inp_subcatchment
			     JOIN temp_node ON inp_subcatchment.outlet_id::text = temp_node.node_id::text
			  WHERE "left"(inp_subcatchment.outlet_id::text, 1) = '{'::text
			UNION
			 SELECT inp_subcatchment.outlet_id,
			    inp_subcatchment.subc_id
			   FROM inp_subcatchment
			  WHERE "left"(inp_subcatchment.outlet_id::text, 1) <> '{'::text) a) b USING (outlet_id);


	CREATE OR REPLACE TEMP VIEW vi_t_subcatchments AS
	 SELECT DISTINCT ve_inp_subcatchment.subc_id,
	    ve_inp_subcatchment.rg_id,
	    b.outlet_id,
	    ve_inp_subcatchment.area,
	    ve_inp_subcatchment.imperv,
	    ve_inp_subcatchment.width,
	    ve_inp_subcatchment.slope,
	    ve_inp_subcatchment.clength,
	    ve_inp_subcatchment.snow_id
	   FROM ve_inp_subcatchment
	     JOIN ( SELECT a.subc_id,
		    a.outlet_id
		   FROM ( SELECT unnest(inp_subcatchment.outlet_id::character varying[]) AS outlet_id,
			    inp_subcatchment.subc_id
			   FROM inp_subcatchment
			     LEFT JOIN temp_t_node ON inp_subcatchment.outlet_id::text = temp_t_node.node_id::text
			  WHERE "left"(inp_subcatchment.outlet_id::text, 1) = '{'::text
			UNION
			 SELECT inp_subcatchment.outlet_id,
			    inp_subcatchment.subc_id
			   FROM inp_subcatchment
			  WHERE "left"(inp_subcatchment.outlet_id::text, 1) <> '{'::text) a) b USING (outlet_id);


	CREATE OR REPLACE TEMP VIEW vi_t_symbols  AS
	 SELECT ve_raingage.rg_id,
	    NULL::numeric(16,3) AS xcoord,
	    NULL::numeric(16,3) AS ycoord,
	    ve_raingage.the_geom
	   FROM ve_raingage;


	CREATE OR REPLACE TEMP VIEW vi_t_temperature  AS
	 SELECT inp_temperature.temp_type,
	    inp_temperature.value
	   FROM inp_temperature;


	CREATE OR REPLACE TEMP VIEW vi_t_transects AS
	 SELECT inp_transects_value.text
	   FROM inp_transects_value
	  ORDER BY inp_transects_value.id;


	CREATE OR REPLACE TEMP VIEW vi_t_treatment AS
	 SELECT temp_t_node_other.node_id,
	    temp_t_node_other.poll_id,
	    temp_t_node_other.other AS function
	   FROM temp_t_node_other
	  WHERE temp_t_node_other.type::text = 'TREATMENT'::text;


	CREATE OR REPLACE TEMP VIEW vi_t_vertices AS
	 SELECT DISTINCT ON (arc.path, arc.point) arc.arc_id,
	    NULL::numeric(16,3) AS xcoord,
	    NULL::numeric(16,3) AS ycoord,
	    arc.point AS the_geom
	   FROM ( SELECT (st_dumppoints(temp_t_arc.the_geom)).geom AS point,
		    (st_dumppoints(temp_t_arc.the_geom)).path AS path,
		    st_startpoint(temp_t_arc.the_geom) AS startpoint,
		    st_endpoint(temp_t_arc.the_geom) AS endpoint,
		    temp_t_arc.sector_id,
		    temp_t_arc.arc_id
		   FROM temp_t_arc) arc
	  WHERE (arc.point < arc.startpoint OR arc.point > arc.startpoint) AND (arc.point < arc.endpoint OR arc.point > arc.endpoint)
	  ORDER BY arc.path;


	CREATE OR REPLACE TEMP VIEW vi_t_washoff  AS
	 SELECT inp_washoff.landus_id,
	    inp_washoff.poll_id,
	    inp_typevalue.id AS funcw_type,
	    inp_washoff.c1,
	    inp_washoff.c2,
	    inp_washoff.sweepeffic,
	    inp_washoff.bmpeffic
	   FROM inp_washoff
	     LEFT JOIN inp_typevalue ON inp_typevalue.id::text = inp_washoff.funcw_type::text
	  WHERE inp_typevalue.typevalue::text = 'inp_value_washoff'::text;


	CREATE OR REPLACE TEMP VIEW vi_t_weirs AS
	 SELECT temp_t_arc.arc_id,
	    temp_t_arc.node_1,
	    temp_t_arc.node_2,
	    f.weir_type,
	    f.offsetval,
	    f.cd,
	    f.flap,
	    f.ec,
	    f.cd2,
	    f.surcharge,
	    f.road_width,
	    f.road_surf,
	    f.coef_curve
	   FROM temp_t_arc_flowregulator f
	     JOIN temp_t_arc ON f.arc_id::text = temp_t_arc.arc_id
	  WHERE f.type::text = 'WEIR'::text;


	CREATE OR REPLACE TEMP VIEW vi_t_xsections AS
	 SELECT temp_t_arc.arc_id,
	    cat_arc_shape.epa AS shape,
	    cat_arc.geom1::text AS other1,
	    cat_arc.curve_id AS other2,
	    0::text AS other3,
	    0::text AS other4,
	    temp_t_arc.barrels AS other5,
	    NULL::text AS other6
	   FROM temp_t_arc
	     JOIN cat_arc ON temp_t_arc.arccat_id::text = cat_arc.id::text
	     JOIN cat_arc_shape ON cat_arc_shape.id::text = cat_arc.shape::text
	  WHERE cat_arc_shape.epa::text = 'CUSTOM'::text AND NOT (temp_t_arc.arc_id IN ( SELECT temp_t_arc_flowregulator.arc_id::text
		   FROM temp_t_arc_flowregulator))
	UNION
	 SELECT temp_t_arc.arc_id,
	    cat_arc_shape.epa AS shape,
	    cat_arc.geom1::text AS other1,
	    cat_arc.geom2::text AS other2,
	    coalesce(cat_arc.geom3::text,'0') AS other3,
	    coalesce (cat_arc.geom4::text,'0') AS other4,
	    temp_t_arc.barrels AS other5,
	    temp_t_arc.culvert::text AS other6
	   FROM temp_t_arc
	     JOIN cat_arc ON temp_t_arc.arccat_id::text = cat_arc.id::text
	     JOIN cat_arc_shape ON cat_arc_shape.id::text = cat_arc.shape::text
	  WHERE (cat_arc_shape.epa::text <> ALL (ARRAY['CUSTOM'::text, 'IRREGULAR'::text])) AND NOT (temp_t_arc.arc_id IN ( SELECT temp_t_arc_flowregulator.arc_id::text
		   FROM temp_t_arc_flowregulator))
	UNION
	 SELECT temp_t_arc.arc_id,
	    cat_arc_shape.epa AS shape,
	    cat_arc.tsect_id AS other1,
	    0::character varying AS other2,
	    0::text AS other3,
	    0::text AS other4,
	    temp_t_arc.barrels AS other5,
	    NULL::text AS other6
	   FROM temp_t_arc
	    JOIN cat_arc ON temp_t_arc.arccat_id::text = cat_arc.id::text
	    JOIN cat_arc_shape ON cat_arc_shape.id::text = cat_arc.shape::text
	  WHERE temp_t_arc.epa_type = 'FRWEIR' OR temp_t_arc.epa_type = 'FRORIFICE'
	UNION
	SELECT temp_t_arc.arc_id,
	    cat_arc_shape.epa AS shape,
	    cat_arc.tsect_id AS other1,
	    0::character varying AS other2,
	    0::text AS other3,
	    0::text AS other4,
	    temp_t_arc.barrels AS other5,
	    NULL::text AS other6
	   FROM temp_t_arc
	     JOIN cat_arc ON temp_t_arc.arccat_id::text = cat_arc.id::text
	     JOIN cat_arc_shape ON cat_arc_shape.id::text = cat_arc.shape::text
	  WHERE cat_arc_shape.epa::text = 'IRREGULAR'::text AND NOT (temp_t_arc.arc_id IN ( SELECT temp_t_arc_flowregulator.arc_id::text
		   FROM temp_t_arc_flowregulator))
	UNION
	 SELECT temp_t_arc_flowregulator.arc_id::text,
	    temp_t_arc_flowregulator.shape,
	    temp_t_arc_flowregulator.geom1::text AS other1,
	    temp_t_arc_flowregulator.geom2::text AS other2,
	    coalesce(temp_t_arc_flowregulator.geom3::text,'0') AS other3,
	    coalesce(temp_t_arc_flowregulator.geom4::text,'0') AS other4,
	    NULL::integer AS other5,
	    NULL::text AS other6
	   FROM temp_t_arc_flowregulator
	  WHERE temp_t_arc_flowregulator.type::text = ANY (ARRAY['ORIFICE'::character varying::text, 'WEIR'::character varying::text]);

	-- temporal views related to other temporal views (last to create first to drop below)

	CREATE OR REPLACE TEMP VIEW vi_t_patterns AS
	 SELECT p.pattern_id,
	    p.pattern_type,
	    inp_pattern_value.factor_1,
	    inp_pattern_value.factor_2,
	    inp_pattern_value.factor_3,
	    inp_pattern_value.factor_4,
	    inp_pattern_value.factor_5,
	    inp_pattern_value.factor_6,
	    inp_pattern_value.factor_7,
	    inp_pattern_value.factor_8,
	    inp_pattern_value.factor_9,
	    inp_pattern_value.factor_10,
	    inp_pattern_value.factor_11,
	    inp_pattern_value.factor_12,
	    inp_pattern_value.factor_13,
	    inp_pattern_value.factor_14,
	    inp_pattern_value.factor_15,
	    inp_pattern_value.factor_16,
	    inp_pattern_value.factor_17,
	    inp_pattern_value.factor_18,
	    inp_pattern_value.factor_19,
	    inp_pattern_value.factor_20,
	    inp_pattern_value.factor_21,
	    inp_pattern_value.factor_22,
	    inp_pattern_value.factor_23,
	    inp_pattern_value.factor_24
	   FROM selector_expl s,
	    inp_pattern p
	     JOIN inp_pattern_value USING (pattern_id)
	     JOIN (select pattern_id FROM vi_t_aquifers UNION select monthly_adj FROM vi_t_adjustments UNION select pattern_id FROM vi_t_inflows UNION
		  select pat1 FROM vi_t_dwf UNION select pat2 FROM vi_t_dwf UNION select pat3 FROM vi_t_dwf UNION select pat4 FROM vi_t_dwf) a USING (pattern_id)
	     WHERE p.active AND p.expl_id = s.expl_id AND s.cur_user = "current_user"()::text
	     union
	      SELECT p.pattern_id,
	    p.pattern_type,
	    inp_pattern_value.factor_1,
	    inp_pattern_value.factor_2,
	    inp_pattern_value.factor_3,
	    inp_pattern_value.factor_4,
	    inp_pattern_value.factor_5,
	    inp_pattern_value.factor_6,
	    inp_pattern_value.factor_7,
	    inp_pattern_value.factor_8,
	    inp_pattern_value.factor_9,
	    inp_pattern_value.factor_10,
	    inp_pattern_value.factor_11,
	    inp_pattern_value.factor_12,
	    inp_pattern_value.factor_13,
	    inp_pattern_value.factor_14,
	    inp_pattern_value.factor_15,
	    inp_pattern_value.factor_16,
	    inp_pattern_value.factor_17,
	    inp_pattern_value.factor_18,
	    inp_pattern_value.factor_19,
	    inp_pattern_value.factor_20,
	    inp_pattern_value.factor_21,
	    inp_pattern_value.factor_22,
	    inp_pattern_value.factor_23,
	    inp_pattern_value.factor_24
	   FROM selector_expl s,
	    inp_pattern p
	     JOIN inp_pattern_value USING (pattern_id)
	     JOIN (select pattern_id FROM vi_t_aquifers UNION select monthly_adj FROM vi_t_adjustments UNION select pattern_id FROM vi_t_inflows UNION
		  select pat1 FROM vi_t_dwf UNION select pat2 FROM vi_t_dwf UNION select pat3 FROM vi_t_dwf UNION select pat4 FROM vi_t_dwf) a USING (pattern_id)
	     WHERE p.active AND p.expl_id is null
	     ORDER BY pattern_id;

	CREATE OR REPLACE TEMP VIEW vi_t_timeseries AS
	SELECT c.* FROM (SELECT
	b.timser_id,
	b.other1,
	b.other2,
	b.other3
    FROM ( SELECT t.id,
			t.timser_id,
			t.other1,
			t.other2,
			t.other3
		   FROM selector_expl s,
			( SELECT a.id,
					a.timser_id,
					a.other1,
					a.other2,
					a.other3,
					a.expl_id
				   FROM ( SELECT inp_timeseries_value.id,
							inp_timeseries_value.timser_id,
							inp_timeseries_value.date AS other1,
							inp_timeseries_value.hour AS other2,
							inp_timeseries_value.value AS other3,
							inp_timeseries.expl_id
						   FROM inp_timeseries_value
							 JOIN inp_timeseries ON inp_timeseries_value.timser_id::text = inp_timeseries.id::text
						  WHERE inp_timeseries.times_type::text = 'ABSOLUTE'::text AND inp_timeseries.active
						UNION
						 SELECT inp_timeseries_value.id,
							inp_timeseries_value.timser_id,
							concat('FILE', ' ', inp_timeseries.fname) AS other1,
							NULL::character varying AS other2,
							NULL::numeric AS other3,
							inp_timeseries.expl_id
						   FROM inp_timeseries_value
							 JOIN inp_timeseries ON inp_timeseries_value.timser_id::text = inp_timeseries.id::text
						  WHERE inp_timeseries.times_type::text = 'FILE'::text AND inp_timeseries.active
						UNION
						 SELECT inp_timeseries_value.id,
							inp_timeseries_value.timser_id,
							NULL::text AS other1,
							inp_timeseries_value."time" AS other2,
							inp_timeseries_value.value::numeric AS other3,
							inp_timeseries.expl_id
						   FROM inp_timeseries_value
							 JOIN inp_timeseries ON inp_timeseries_value.timser_id::text = inp_timeseries.id::text
						  WHERE inp_timeseries.times_type::text = 'RELATIVE'::text AND inp_timeseries.active) a
				  ORDER BY a.id) t
		  WHERE (t.expl_id = s.expl_id AND s.cur_user = "current_user"()::text)
		  union
		  SELECT t.id,
			t.timser_id,
			t.other1,
			t.other2,
			t.other3
		   FROM
			( SELECT a.id,
					a.timser_id,
					a.other1,
					a.other2,
					a.other3,
					a.expl_id
				   FROM ( SELECT inp_timeseries_value.id,
							inp_timeseries_value.timser_id,
							inp_timeseries_value.date AS other1,
							inp_timeseries_value.hour AS other2,
							inp_timeseries_value.value AS other3,
							inp_timeseries.expl_id
						   FROM inp_timeseries_value
							 JOIN inp_timeseries ON inp_timeseries_value.timser_id::text = inp_timeseries.id::text
						  WHERE inp_timeseries.times_type::text = 'ABSOLUTE'::text AND inp_timeseries.active
						UNION
						 SELECT inp_timeseries_value.id,
							inp_timeseries_value.timser_id,
							concat('FILE', ' ', inp_timeseries.fname) AS other1,
							NULL::character varying AS other2,
							NULL::numeric AS other3,
							inp_timeseries.expl_id
						   FROM inp_timeseries_value
							 JOIN inp_timeseries ON inp_timeseries_value.timser_id::text = inp_timeseries.id::text
						  WHERE inp_timeseries.times_type::text = 'FILE'::text AND inp_timeseries.active
						UNION
						 SELECT inp_timeseries_value.id,
							inp_timeseries_value.timser_id,
							NULL::text AS other1,
							inp_timeseries_value."time" AS other2,
							inp_timeseries_value.value::numeric AS other3,
							inp_timeseries.expl_id
						   FROM inp_timeseries_value
							 JOIN inp_timeseries ON inp_timeseries_value.timser_id::text = inp_timeseries.id::text
						  WHERE inp_timeseries.times_type::text = 'RELATIVE'::text AND inp_timeseries.active) a
				  ORDER BY a.id) t
		  WHERE t.expl_id is NULL) b
  	ORDER BY b.id) c
	JOIN inp_timeseries ON id = timser_id
	WHERE (timser_type = 'Rainfall' and timser_id IN (SELECT timser_id FROM t_rpt_inp_raingage)) or timser_type != 'Rainfall'::text
	ORDER BY timser_id, other2;


	CREATE OR REPLACE TEMP VIEW vi_t_curves AS
	 SELECT a.curve_id,
	    a.curve_type,
	    a.x_value,
	    a.y_value
	   FROM ( WITH qt AS (
			 SELECT inp_curve_value.id,
			    inp_curve_value.curve_id,
				CASE
				    WHEN inp_curve_value.id = (( SELECT min(sub.id) AS min
				       FROM inp_curve_value sub
				      WHERE sub.curve_id::text = inp_curve_value.curve_id::text)) THEN inp_typevalue.id
				    ELSE NULL::character varying
				END AS curve_type,
			    inp_curve_value.x_value,
			    inp_curve_value.y_value,
			    c.expl_id
			   FROM inp_curve c
			     JOIN inp_curve_value ON c.id::text = inp_curve_value.curve_id::text
			     LEFT JOIN inp_typevalue ON inp_typevalue.id::text = c.curve_type::text
			  WHERE inp_typevalue.typevalue::text = 'inp_value_curve'::text AND c.active
			)
		 SELECT qt.id,
		    qt.curve_id,
		    qt.curve_type,
		    qt.x_value,
		    qt.y_value,
		    qt.expl_id
		   FROM qt
		     JOIN selector_expl s USING (expl_id)
		  WHERE s.cur_user = "current_user"()::text
		UNION
		 SELECT qt.id,
		    qt.curve_id,
		    qt.curve_type,
		    qt.x_value,
		    qt.y_value,
		    qt.expl_id
		   FROM qt
		  WHERE qt.expl_id IS NULL) a
		  JOIN (SELECT curve_id FROM vi_t_pumps UNION SELECT other1 FROM vi_t_dividers UNION SELECT other1 FROM vi_t_outfalls UNION
			SELECT other1 FROM vi_t_outlets UNION SELECT other1 FROM vi_t_storage UNION SELECT other2 FROM vi_t_xsections) b USING (curve_id)
	  ORDER BY a.id;

	--node
	FOR rec_table IN SELECT * FROM config_fprocess WHERE fid=v_fid order by orderby
	LOOP
		-- insert header
		IF rec_table.tablename IN ('vi_t_gully') AND v_exportmode = 1 THEN
			-- nothing because this targets does not to be exported

		ELSIF rec_table.tablename IN ('vi_t_subareas', 'vi_t_subcatchments', 'vi_t_infiltration', 'vi_t_raingages', 'vi_t_landuses', 'vi_t_coverages', 'vi_t_buildup', 'vi_t_washoff',
		'vi_t_lid_controls', 'vi_t_lid_usage', 'vi_t_snowpacks') AND v_exportmode = 2 THEN
			-- nothing because this targets does not to be exported

		ELSE
			INSERT INTO temp_t_csv (csv1,fid) VALUES (NULL,v_fid);
			EXECUTE 'INSERT INTO temp_t_csv(fid,csv1) VALUES ('||v_fid||','''|| rec_table.target||''');';

			INSERT INTO temp_t_csv (fid,csv1,csv2,csv3,csv4,csv5,csv6,csv7,csv8,csv9,csv10,csv11,csv12,csv13,csv14,csv15,csv16,csv17,csv18,csv19,csv20,csv21,csv22,csv23,csv24,csv25,csv26, csv27, csv28, csv29, csv30)
			SELECT v_fid,rpad(concat(';;',c1),20),rpad(c2,20),rpad(c3,20),rpad(c4,20),rpad(c5,20),rpad(c6,20),rpad(c7,20),rpad(c8,20),rpad(c9,20),rpad(c10,20),rpad(c11,20),rpad(c12,20)
			,rpad(c13,20),rpad(c14,20),rpad(c15,20),rpad(c16,20),rpad(c17,20),rpad(c18,20),rpad(c19,20),rpad(c20,20),rpad(c21,20),rpad(c22,20),rpad(c23,20),rpad(c24,20),rpad(c25,20),rpad(c26,20)
			,rpad(c27,20),rpad(c28,20),rpad(c29,20),rpad(c30,20)
			FROM crosstab('SELECT table_name::text,  data_type::text, column_name::text FROM information_schema.columns WHERE table_name='''||rec_table.tablename||'''::text')
			AS rpt(table_name text, c1 text, c2 text, c3 text, c4 text, c5 text, c6 text, c7 text, c8 text, c9 text, c10 text, c11 text, c12 text, c13 text, c14 text, c15 text,
			c16 text, c17 text, c18 text, c19 text, c20 text, c21 text, c22 text, c23 text, c24 text, c25 text, c26 text, c27 text, c28 text, c29 text, c30 text);

			INSERT INTO temp_t_csv (fid) VALUES (141) RETURNING id INTO id_last;

			SELECT count(*)::text INTO num_column from information_schema.columns where table_name=rec_table.tablename;

			--add underlines
			FOR num_col_rec IN 1..num_column
			LOOP
				IF num_col_rec=1 then
					EXECUTE 'UPDATE temp_t_csv set csv1=rpad('';;----------'',20) WHERE id='||id_last||';';
				ELSE
					EXECUTE 'UPDATE temp_t_csv SET csv'||num_col_rec||'=rpad(''----------'',20) WHERE id='||id_last||';';
				END IF;
			END LOOP;

			-- insert values
			CASE WHEN rec_table.tablename = 'vi_t_coordinates' THEN
				-- on the fly transformation of epsg
				INSERT INTO temp_t_csv SELECT nextval('temp_csv_id_seq'::regclass), v_fid, current_user,'vi_t_coordinates',
				node_id, ROUND(ST_x(ST_transform(the_geom, v_client_epsg))::numeric, 3), ROUND(ST_y(ST_transform(the_geom, v_client_epsg))::numeric, 3)  FROM vi_t_coordinates;

			WHEN rec_table.tablename = 'vi_t_vertices' THEN
				-- on the fly transformation of epsg
				INSERT INTO temp_t_csv SELECT nextval('temp_csv_id_seq'::regclass), v_fid, current_user,'vi_t_vertices',
				arc_id, ROUND(ST_x(ST_transform(the_geom, v_client_epsg))::numeric, 3), ROUND(ST_y(ST_transform(the_geom, v_client_epsg))::numeric, 3)  FROM vi_t_vertices;

			WHEN rec_table.tablename = 'vi_t_symbols' THEN
				-- on the fly transformation of epsg
				INSERT INTO temp_t_csv SELECT nextval('temp_csv_id_seq'::regclass), v_fid, current_user,'vi_t_symbols',
				rg_id, ROUND(ST_x(ST_transform(the_geom, v_client_epsg))::numeric, 3), ROUND(ST_y(ST_transform(the_geom, v_client_epsg))::numeric, 3)  FROM vi_t_symbols;
			ELSE
				EXECUTE 'INSERT INTO temp_t_csv SELECT nextval(''temp_csv_id_seq''::regclass),'||v_fid||',current_user,'''||rec_table.tablename::text||''',*  FROM '||rec_table.tablename||';';
			END CASE;
		END IF;
	END LOOP;

	-- build return
	select (array_to_json(array_agg(row_to_json(row))))::json
	into v_return
		from ( select text from (
		select id, concat(rpad(csv1,20), ' ', rpad(csv2,20), ' ', rpad(csv3,20), ' ', rpad(csv4,20), ' ', rpad(csv5,20), ' ', rpad(csv6,20), ' ', rpad(csv7,20), ' ', rpad(csv8,20), ' ', rpad(csv9,20), ' ', rpad(csv10,20),
		' ', rpad(csv11,20), ' ', rpad(csv12,20), ' ', rpad(csv13,20), ' ', rpad(csv14,20), ' ', rpad(csv15,20), ' ', rpad(csv16,20), ' ', rpad(csv17,20), ' ', rpad(csv18,20), ' ', rpad(csv19,20), ' ', rpad(csv20,20),
		' ', rpad(csv21,20), ' ', rpad(csv22,20), ' ', rpad(csv23,20), ' ', rpad(csv24,20), ' ', rpad(csv25,20), ' ', rpad(csv26,20), ' ', rpad(csv27,20), ' ', rpad(csv28,20), ' ', rpad(csv29,20), ' ', rpad(csv30,20)) as text
			from temp_t_csv where fid = 141 and cur_user = current_user and source is null
		union
			select id, csv1 as text from temp_t_csv where fid  = 141 and cur_user = current_user and source in ('vi_t_transects','vi_t_controls','vi_t_rules', 'vi_t_hydrographs','vi_t_polygons')
		union
			select id, concat(rpad(csv1,20), ' ', rpad(coalesce(csv2,''),20), ' ', rpad(coalesce(csv3,''),20), ' ', rpad(coalesce(csv4,''),20), ' ', rpad(coalesce(csv5,''),20), ' ', rpad(coalesce(csv6,''),20), ' ', csv7) as text
			from temp_t_csv where fid  = 141 and cur_user = current_user and source in ('vi_t_junctions')
		union
			select id, concat(rpad(csv1,20), ' ', rpad(coalesce(csv2,''),20), ' ', rpad(coalesce(csv3,''),20), ' ', rpad(coalesce(csv4,''),20), ' ', rpad(coalesce(csv5,''),20), ' ', rpad(coalesce(csv6,''),20),
			' ', rpad(coalesce(csv7,''),20) , ' ', rpad(coalesce(csv8,''),20), ' ', rpad(coalesce(csv8,''),20), ' ',
			csv10) as text from temp_t_csv where fid  = 141 and cur_user = current_user and source in ('vi_t_conduits')
		union
			select id, concat(rpad(csv1,20), ' ', csv2)as text from temp_t_csv where fid = 141 and cur_user = current_user and source in ('header', 'vi_t_evaporation','vi_t_temperature', 'vi_t_report', 'vi_t_map')
		union
			select id, concat(rpad(csv1,20), ' ', rpad(coalesce(csv2,''),20), ' ', csv3)as text from temp_t_csv where fid = 141 and cur_user = current_user and source in ('vi_t_files', 'vi_t_adjustments')
		union
			select id,
			case when  substring(csv2,0,5) = 'FILE' THEN concat(rpad(csv1,20),' ',rpad(coalesce(csv2,''),length(csv2)+2))
			ELSE concat(rpad(csv1,20),' ',rpad(coalesce(csv2,''),20),' ', rpad(coalesce(csv3,''),20), rpad(coalesce(csv4,''),20),' ', rpad(coalesce(csv5,''),20)) END
			from temp_t_csv where fid = 141 and cur_user = current_user and source in ('vi_t_timeseries')
		union
			select id,
			case when csv5 = 'FILE' THEN concat(rpad(csv1,20),' ',rpad(coalesce(csv2,''),20),' ', rpad(coalesce(csv3,''),20),' ',rpad(coalesce(csv4,''),20),' ',rpad(coalesce(csv5,''),20),' ',rpad(coalesce(csv6,''),length(csv6)+2),
					' ',rpad(coalesce(csv7,''),20),' ',rpad(coalesce(csv8,''),20))
					ELSE concat(rpad(csv1,20),' ',rpad(coalesce(csv2,''),20),' ', rpad(coalesce(csv3,''),20),' ',rpad(coalesce(csv4,''),20),' ',rpad(coalesce(csv5,''),20),' ',rpad(coalesce(csv6,''),20),
					' ',rpad(coalesce(csv7,''),20),' ',rpad(coalesce(csv8,''),20)) END
			from temp_t_csv where fid = 141 and cur_user = current_user and source in ('vi_t_raingages')
		union
			select id, concat(rpad(csv1,20),' ',rpad(coalesce(csv2,''),20),' ', rpad(coalesce(csv3,''),20),' ',rpad(coalesce(csv4,''),20),' ',rpad(coalesce(csv5,''),20),' ',rpad(coalesce(csv6,''),20),
			' ',rpad(coalesce(csv7,''),20),' ',rpad(coalesce(csv8,''),20),' ',rpad(coalesce(csv9,''),20),' ',rpad(coalesce(csv10,''),20),' ',rpad(coalesce(csv11,''),20),' ',rpad(coalesce(csv12,''),20),
			' ',rpad(coalesce(csv13,''),20),' ',rpad(coalesce(csv14,''),20),' ',rpad(coalesce(csv15,''),20),' ', rpad(coalesce(csv16,''),20),' ',rpad(coalesce(csv17,''),20),' ',rpad(coalesce(csv18,''),20),
			' ', rpad(coalesce(csv19,''),20), ' ',rpad(coalesce(csv20,''),20),' ',rpad(coalesce(csv21,''),20),' ',rpad(coalesce(csv22,''),20),' ',rpad(coalesce(csv23,''),20),' ',rpad(coalesce(csv24,''),20),
			' ', rpad(coalesce(csv25,''),20),' ',rpad(coalesce(csv26,''),20),' ',rpad(coalesce(csv27,''),20),' ', rpad(coalesce(csv28,''),20), ' ', rpad(coalesce(csv29,''),20),' ',rpad(coalesce(csv30,''),20)) as text
			from temp_t_csv where fid  = 141 and cur_user = current_user and source not in
			('header','vi_t_controls','vi_t_rules', 'vi_t_adjustments','vi_t_evaporation', 'vi_t_files','vi_t_hydrographs','vi_t_polygons','vi_t_temperature','vi_t_transects',
			'vi_t_raingages','vi_t_timeseries', 'vi_t_report', 'vi_t_map', 'vi_t_junctions', 'vi_t_conduits')
		order by id
		)a )row;

	--drop TEMP views
	DROP VIEW IF EXISTS vi_t_timeseries;
	DROP VIEW IF EXISTS vi_t_curves;
	DROP VIEW IF EXISTS vi_t_patterns;

	DROP VIEW IF EXISTS vi_t_adjustments;
	DROP VIEW IF EXISTS vi_t_aquifers;
	DROP VIEW IF EXISTS vi_t_buildup;
	DROP VIEW IF EXISTS vi_t_conduits;
	DROP VIEW IF EXISTS vi_t_controls;
	DROP VIEW IF EXISTS vi_t_coordinates;
	DROP VIEW IF EXISTS vi_t_coverages;
	DROP VIEW IF EXISTS vi_t_dividers;
	DROP VIEW IF EXISTS vi_t_dwf;
	DROP VIEW IF EXISTS vi_t_evaporation;
	DROP VIEW IF EXISTS vi_t_files;
	DROP VIEW IF EXISTS vi_t_groundwater;
	DROP VIEW IF EXISTS vi_t_gully;
	DROP VIEW IF EXISTS vi_t_gwf;
	DROP VIEW IF EXISTS vi_t_hydrographs;
	DROP VIEW IF EXISTS vi_t_infiltration;
	DROP VIEW IF EXISTS vi_t_inflows;
	DROP VIEW IF EXISTS vi_t_junctions;
	DROP VIEW IF EXISTS vi_t_labels;
	DROP VIEW IF EXISTS vi_t_landuses;
	DROP VIEW IF EXISTS vi_t_lid_controls;
	DROP VIEW IF EXISTS vi_t_lid_usage;
	DROP VIEW IF EXISTS vi_t_loadings;
	DROP VIEW IF EXISTS vi_t_losses;
	DROP VIEW IF EXISTS vi_t_map;
	DROP VIEW IF EXISTS vi_t_options;
	DROP VIEW IF EXISTS vi_t_orifices;
	DROP VIEW IF EXISTS vi_t_outfalls;
	DROP VIEW IF EXISTS vi_t_outlets;
	DROP VIEW IF EXISTS vi_t_pollutants;
	DROP VIEW IF EXISTS vi_t_polygons;
	DROP VIEW IF EXISTS vi_t_pumps;
	DROP VIEW IF EXISTS vi_t_raingages;
	DROP VIEW IF EXISTS vi_t_rdii;
	DROP VIEW IF EXISTS vi_t_report;
	DROP VIEW IF EXISTS vi_t_snowpacks;
	DROP VIEW IF EXISTS vi_t_storage;
	DROP VIEW IF EXISTS vi_t_subareas;
	DROP VIEW IF EXISTS vi_t_subcatchments;
	DROP VIEW IF EXISTS vi_t_symbols;
	DROP VIEW IF EXISTS vi_t_treatment;
	DROP VIEW IF EXISTS vi_t_vertices;
	DROP VIEW IF EXISTS vi_t_washoff;
	DROP VIEW IF EXISTS vi_t_weirs;
	DROP VIEW IF EXISTS vi_t_xsections;
	DROP VIEW IF EXISTS vi_t_temperature;
	DROP VIEW IF EXISTS vi_t_transects;

	RETURN v_return;

END;$function$;
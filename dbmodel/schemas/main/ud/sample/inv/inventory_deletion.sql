/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = "SCHEMA_NAME", public, pg_catalog;

UPDATE config_param_user SET value = true where parameter = 'plan_psector_force_delete';

UPDATE arc a SET sector_id = s.sector_id FROM sector s WHERE s.code = a.expl_id::text AND s.sector_id > 0;
UPDATE node n SET sector_id = s.sector_id FROM sector s WHERE s.code = n.expl_id::text AND s.sector_id > 0;
UPDATE connec c SET sector_id = s.sector_id FROM sector s WHERE s.code = c.expl_id::text AND s.sector_id > 0;
UPDATE gully g SET sector_id = s.sector_id FROM sector s WHERE s.code = g.expl_id::text AND s.sector_id > 0;
UPDATE link l SET sector_id = s.sector_id FROM sector s WHERE s.code = l.expl_id::text AND s.sector_id > 0;
UPDATE element e SET sector_id = s.sector_id FROM sector s WHERE s.code = e.expl_id::text AND s.sector_id > 0;

DELETE FROM inp_controls;

DELETE FROM sector WHERE sector_id > 0 AND code NOT IN ('1', '2');

UPDATE sector s SET the_geom = e.the_geom FROM exploitation e WHERE s.code = e.expl_id::text AND s.sector_id > 0;

UPDATE inp_junction SET y0=null, ysur=null, apond=null, outfallparam=null;
UPDATE inp_conduit SET q0=null, qmax=null;
UPDATE inp_storage SET storage_type =null, curve_id = null, y0=null, ysur=null;
UPDATE inp_outfall SET outfall_type = null;

DELETE FROM inp_frweir;
DELETE FROM inp_frpump;
DELETE FROM inp_frorifice;
DELETE FROM inp_froutlet;

UPDATE inp_weir SET weir_type=null, offsetval=null, cd=null, geom1=null, geom2=null, geom3=null, geom4=null;
UPDATE inp_pump SET curve_id=null, status=null, startup=null , shutoff=null;

UPDATE cat_material SET n = null;

DELETE FROM inp_dwf;
DELETE FROM inp_pattern;
DELETE FROM inp_curve;

DELETE FROM cat_hydrology;
DELETE FROM cat_dwf;
DELETE FROM cat_dscenario;
DELETE FROM plan_psector;

DELETE FROM rpt_cat_result;

UPDATE config_param_user SET value = false where parameter = 'plan_psector_force_delete';
UPDATE inp_gully SET outlet_type =null,  gully_method = null, weir_cd =null , orifice_cd =null , efficiency =null ;

DELETE FROM raingage;
DELETE from inp_timeseries;
DELETE from inp_lid;

-- orrifice in node 237
DELETE FROM "element" WHERE element_id = 100021;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/



SET search_path = SCHEMA_NAME, public, pg_catalog;

ALTER TABLE sector DISABLE TRIGGER gw_trg_edit_controls;
ALTER TABLE dqa DISABLE TRIGGER gw_trg_edit_controls;

UPDATE config_param_user SET value = true where parameter = 'plan_psector_force_delete';

UPDATE arc a SET sector_id = s.sector_id FROM sector s WHERE s.code = a.expl_id::text AND s.sector_id > 0;
UPDATE node n SET sector_id = s.sector_id FROM sector s WHERE s.code = n.expl_id::text AND s.sector_id > 0;
UPDATE connec c SET sector_id = s.sector_id FROM sector s WHERE s.code = c.expl_id::text AND s.sector_id > 0;
UPDATE link l SET sector_id = s.sector_id FROM sector s WHERE s.code = l.expl_id::text AND s.sector_id > 0;
UPDATE element e SET sector_id = s.sector_id FROM sector s WHERE s.code = e.expl_id::text AND s.sector_id > 0;

DELETE FROM inp_rules;
DELETE FROM inp_controls;

DELETE FROM sector WHERE sector_id > 0 AND code NOT IN ('1', '2');

UPDATE sector s SET the_geom = e.the_geom FROM exploitation e WHERE s.code = e.expl_id::text AND s.sector_id > 0;
UPDATE sector SET "name"='sector2-1s', expl_id='{2}', macrosector_id=2 WHERE code = '2' AND sector_id > 0;

UPDATE inp_valve SET valve_type =NULL, custom_dint=null;
UPDATE inp_pump SET curve_id = null, status= null, pump_type = null;
UPDATE inp_pump_additional SET curve_id = null, status= null;
UPDATE inp_reservoir SET head = null, pattern_id = null;
UPDATE inp_inlet SET head = null, pattern_id = null, initlevel=null, minlevel=null, maxlevel=null, diameter=null, curve_id=null, overflow=null;
UPDATE inp_junction SET demand=null, pattern_id = null;
UPDATE inp_connec SET demand=null, pattern_id = null;

UPDATE ext_cat_hydrometer_category SET pattern_id = null;
UPDATE dma SET pattern_id = null;
UPDATE sector SET pattern_id = null;

DELETE FROM cat_dscenario;

DELETE FROM inp_pattern;
DELETE FROM inp_curve;

DELETE FROM plan_psector;

UPDATE cat_mat_roughness SET roughness = null;

DELETE FROM rpt_cat_result;

UPDATE config_param_user SET value = false where parameter = 'plan_psector_force_delete';

DELETE FROM inp_pump_additional;

UPDATE arc SET dqa_id=0 ;
UPDATE node SET dqa_id=0 ;
UPDATE connec SET dqa_id=0 ;
UPDATE link SET dqa_id=0 ;

DELETE FROM dqa WHERE dqa_id > 0;

UPDATE man_valve SET to_arc=null WHERE node_id = 1083;
UPDATE inp_valve SET setting=null WHERE node_id = 1083;
UPDATE man_pump SET to_arc=null WHERE node_id = 1105;

ALTER TABLE sector ENABLE TRIGGER gw_trg_edit_controls;
ALTER TABLE dqa ENABLE TRIGGER gw_trg_edit_controls;

UPDATE man_valve SET to_arc=null WHERE node_id = 1107;

UPDATE cat_soil SET m2trenchl_cost=NULL,m3excess_cost=NULL,m3fill_cost=NULL,b=NULL,m3exc_cost=NULL,trenchlining=NULL,y_param=NULL;
UPDATE cat_pavement SET m2_cost=NULL,thickness=NULL;
UPDATE cat_arc SET z1=NULL,dint=NULL,m3protec_cost=NULL,z2=NULL,m2bottom_cost=NULL,dext=NULL,estimated_depth=NULL,"cost"=NULL,width=NULL,cost_unit=NULL,area=NULL;

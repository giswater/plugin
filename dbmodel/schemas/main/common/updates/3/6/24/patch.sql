/*
This file is part of Giswater 3
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
This version of Giswater is provided by Giswater Association
*/

SET search_path = SCHEMA_NAME, public, pg_catalog;


-- selector network
CREATE TABLE IF NOT EXISTS selector_network (
	network_id int4 NOT NULL,
	cur_user text DEFAULT CURRENT_USER NOT NULL,
	CONSTRAINT selector_network_pkey PRIMARY KEY (network_id, cur_user)
);

insert into config_param_system (parameter,value, descript, isenabled, project_type, datatype, widgettype) VALUES
('basic_selector_tab_network', '{"table":"temp_network","selector":"selector_network","table_id":"network_id","selector_id":"network_id","label":"network_id, '' - '', name","orderBy":"network_id","manageAll":true,"query_filter":"","typeaheadFilter":" AND lower(concat(network_id, '' - '', name))","selectionMode":"keepPreviousUsingShift", "orderbyCheck":false}',
'Variable to configura all options related to search for the specificic tab	Selector variables',true,'utils','json','text');


UPDATE sys_table SET sys_role='role_basic' WHERE id='anl_connec';
UPDATE sys_table SET sys_role='role_basic' WHERE id='anl_node';
UPDATE sys_table SET sys_role='role_basic' WHERE id='anl_arc';


insert into config_form_tabs (formname, tabname, label, tooltip, sys_role, orderby, device) VALUES
('selector_basic','tab_network','Network','Network','role_basic',-1,'{5}');

insert into om_typevalue values ('network_type','1','WATER SUPPLY');
insert into om_typevalue values ('network_type','2','URBAN DRAINAGE');

INSERT INTO config_param_system ("parameter",value,descript,"label",dv_querytext,dv_filterbyfield,isenabled,layoutorder,project_type,dv_isparent,isautoupdate,"datatype",widgettype,ismandatory,iseditable,dv_orderby_id,dv_isnullvalue,stylesheet,widgetcontrols,placeholder,standardvalue,layoutname) VALUES
	 ('basic_selector_sectorisexplismuni','false','Variable to configure that explotation and sector has the same code in order to make a direct correlation one each other','Selector variables',NULL,NULL,true,NULL,'utils',NULL,NULL,'boolean',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
	 	 on conflict (parameter) do nothing;

INSERT INTO sys_table (id, descript, sys_role, "source") VALUES('selector_network', 'Selector of the network', 'role_basic', 'core');

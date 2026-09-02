/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = "SCHEMA_NAME", public, pg_catalog;

--
-- Name: arc gw_trg_arc_link_update; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_arc_link_update AFTER UPDATE OF the_geom ON arc FOR EACH ROW EXECUTE FUNCTION gw_trg_arc_link_update();


--
-- Name: arc gw_trg_arc_noderotation_update; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_arc_noderotation_update AFTER INSERT OR DELETE OR UPDATE OF the_geom ON arc FOR EACH ROW EXECUTE FUNCTION gw_trg_arc_noderotation_update();


--
-- Name: ext_cat_period gw_trg_calculate_period; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_calculate_period AFTER INSERT ON ext_cat_period FOR EACH ROW EXECUTE FUNCTION gw_trg_calculate_period();


--
-- Name: cat_dscenario gw_trg_cat_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_cat_dscenario AFTER INSERT ON cat_dscenario FOR EACH ROW EXECUTE FUNCTION gw_trg_cat_dscenario();


--
-- Name: cat_feature gw_trg_cat_feature_after; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_cat_feature_after AFTER INSERT OR DELETE OR UPDATE ON cat_feature FOR EACH ROW EXECUTE FUNCTION gw_trg_cat_feature();


--
-- Name: cat_feature gw_trg_cat_feature_delete; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_cat_feature_delete BEFORE DELETE ON cat_feature FOR EACH ROW EXECUTE FUNCTION gw_trg_cat_feature('DELETE');


--
-- Name: cat_manager gw_trg_cat_manager; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_cat_manager AFTER INSERT OR DELETE OR UPDATE ON cat_manager FOR EACH ROW EXECUTE FUNCTION gw_trg_cat_manager();


--
-- Name: cat_brand gw_trg_config_control; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_config_control AFTER INSERT OR UPDATE OF featurecat_id ON cat_brand FOR EACH ROW EXECUTE FUNCTION gw_trg_config_control('cat_brand');


--
-- Name: cat_brand_model gw_trg_config_control; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_config_control AFTER INSERT OR UPDATE OF featurecat_id ON cat_brand_model FOR EACH ROW EXECUTE FUNCTION gw_trg_config_control('cat_brand_model');


--
-- Name: config_form_fields gw_trg_config_control; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_config_control BEFORE INSERT OR DELETE OR UPDATE ON config_form_fields FOR EACH ROW EXECUTE FUNCTION gw_trg_config_control('config_form_fields');


--
-- Name: man_type_category gw_trg_config_control; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_config_control AFTER INSERT OR UPDATE OF featurecat_id ON man_type_category FOR EACH ROW EXECUTE FUNCTION gw_trg_config_control('man_type_category');


--
-- Name: man_type_fluid gw_trg_config_control; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_config_control AFTER INSERT OR UPDATE OF featurecat_id ON man_type_fluid FOR EACH ROW EXECUTE FUNCTION gw_trg_config_control('man_type_fluid');


--
-- Name: man_type_function gw_trg_config_control; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_config_control AFTER INSERT OR UPDATE OF featurecat_id ON man_type_function FOR EACH ROW EXECUTE FUNCTION gw_trg_config_control('man_type_function');


--
-- Name: man_type_location gw_trg_config_control; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_config_control AFTER INSERT OR UPDATE OF featurecat_id ON man_type_location FOR EACH ROW EXECUTE FUNCTION gw_trg_config_control('man_type_location');


--
-- Name: sys_param_user gw_trg_config_control; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_config_control BEFORE INSERT OR DELETE OR UPDATE ON sys_param_user FOR EACH ROW EXECUTE FUNCTION gw_trg_config_control('sys_param_user');


--
-- Name: connec gw_trg_connec_proximity_insert; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_connec_proximity_insert BEFORE INSERT ON connec FOR EACH ROW EXECUTE FUNCTION gw_trg_connec_proximity();


--
-- Name: connec gw_trg_connec_proximity_update; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_connec_proximity_update AFTER UPDATE OF the_geom ON connec FOR EACH ROW EXECUTE FUNCTION gw_trg_connec_proximity();


--
-- Name: connec gw_trg_connect_update; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_connect_update AFTER UPDATE OF arc_id, pjoint_id, pjoint_type, the_geom ON connec FOR EACH ROW EXECUTE FUNCTION gw_trg_connect_update('connec');


--
-- Name: gully gw_trg_connect_update; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_connect_update AFTER UPDATE OF arc_id, pjoint_id, pjoint_type, the_geom ON gully FOR EACH ROW EXECUTE FUNCTION gw_trg_connect_update('gully');


--
-- Name: doc gw_trg_doc; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_doc BEFORE INSERT ON doc FOR EACH ROW EXECUTE FUNCTION gw_trg_doc();


--
-- Name: v_ext_address gw_trg_edit_address; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_address INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ext_address FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_address();


--
-- Name: v_edit_arc gw_trg_edit_arc; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_arc INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_arc('parent');


--
-- Name: v_edit_cad_auxcircle gw_trg_edit_cad_aux; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_cad_aux INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_cad_auxcircle FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_cad_aux('circle');


--
-- Name: v_edit_cad_auxline gw_trg_edit_cad_aux; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_cad_aux INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_cad_auxline FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_cad_aux('line');


--
-- Name: v_edit_cad_auxpoint gw_trg_edit_cad_aux; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_cad_aux INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_cad_auxpoint FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_cad_aux('point');


--
-- Name: v_edit_cat_dscenario gw_trg_edit_cat_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_cat_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_cat_dscenario FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_cat_dscenario();

--
-- Name: v_edit_cat_feature_node gw_trg_edit_cat_feature; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_cat_feature INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_cat_feature_node FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_cat_feature('node');


--
-- Name: v_edit_cat_feature_arc gw_trg_edit_cat_feature; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_cat_feature INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_cat_feature_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_cat_feature('arc');


--
-- Name: v_edit_cat_feature_connec gw_trg_edit_cat_feature; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_cat_feature INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_cat_feature_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_cat_feature('connec');


--
-- Name: v_edit_cat_feature_gully gw_trg_edit_cat_feature; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_cat_feature INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_cat_feature_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_cat_feature('gully');


--
-- Name: ve_config_addfields gw_trg_edit_config_addfields; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_config_addfields INSTEAD OF UPDATE ON ve_config_addfields FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_config_addfields();


--
-- Name: ve_config_sysfields gw_trg_edit_config_sysfields; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_config_sysfields INSTEAD OF UPDATE ON ve_config_sysfields FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_config_sysfields();


--
-- Name: v_edit_connec gw_trg_edit_connec; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_connec('parent');


--
-- Name: v_edit_dimensions gw_trg_edit_dimensions; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_dimensions INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_dimensions FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_dimensions('dimensions');


--
-- Name: v_edit_dma gw_trg_edit_dma; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_dma INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_dma FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_dma('dma');


--
-- Name: v_edit_drainzone gw_trg_edit_drainzone; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_drainzone INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_drainzone FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_drainzone();


--
-- Name: v_edit_element gw_trg_edit_element; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_element INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_element FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_element('element');


--
-- Name: ve_pol_element gw_trg_edit_element_pol; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_element_pol INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_pol_element FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_element_pol();


--
-- Name: v_edit_exploitation gw_trg_edit_exploitation; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_exploitation INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_exploitation FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_exploitation();


--
-- Name: arc gw_trg_edit_foreignkey; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_foreignkey AFTER DELETE OR UPDATE OF arc_id ON arc FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_foreignkey('arc_id');


--
-- Name: connec gw_trg_edit_foreignkey; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_foreignkey AFTER DELETE OR UPDATE OF connec_id ON connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_foreignkey('connec_id');


--
-- Name: gully gw_trg_edit_foreignkey; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_foreignkey AFTER DELETE OR UPDATE OF gully_id ON gully FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_foreignkey('gully_id');


--
-- Name: inp_dscenario_lid_usage gw_trg_edit_foreignkey; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_foreignkey AFTER INSERT OR DELETE OR UPDATE OF subc_id ON inp_dscenario_lid_usage FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_foreignkey('inp_dscenario_lid_usage');


--
-- Name: inp_subcatchment gw_trg_edit_foreignkey; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_foreignkey AFTER INSERT OR DELETE OR UPDATE OF subc_id ON inp_subcatchment FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_foreignkey('inp_subcatchment');


--
-- Name: node gw_trg_edit_foreignkey; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_foreignkey AFTER DELETE OR UPDATE OF node_id ON node FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_foreignkey('node_id');


--
-- Name: v_edit_gully gw_trg_edit_gully; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_gully INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_gully('parent');


--
-- Name: v_edit_cat_hydrology gw_trg_edit_hydrology; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_hydrology INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_cat_hydrology FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_hydrology('cat_hydrology');


--
-- Name: v_edit_inp_conduit gw_trg_edit_inp_arc_conduit; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_arc_conduit INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_conduit FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_arc('inp_conduit');


--
-- Name: v_edit_inp_orifice gw_trg_edit_inp_arc_orifice; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_arc_orifice INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_orifice FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_arc('inp_orifice');


--
-- Name: v_edit_inp_outlet gw_trg_edit_inp_arc_outlet; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_arc_outlet INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_outlet FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_arc('inp_outlet');


--
-- Name: v_edit_inp_pump gw_trg_edit_inp_arc_pump; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_arc_pump INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_pump FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_arc('inp_pump');


--
-- Name: v_edit_inp_virtual gw_trg_edit_inp_arc_virtual; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_arc_virtual INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_virtual FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_arc('inp_virtual');


--
-- Name: v_edit_inp_weir gw_trg_edit_inp_arc_weir; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_arc_weir INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_weir FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_arc('inp_weir');


--
-- Name: v_edit_inp_controls gw_trg_edit_inp_controls; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_controls INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_controls FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_controls();


--
-- Name: v_edit_inp_coverage gw_trg_edit_inp_coverage; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_coverage INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_coverage FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_coverage();


--
-- Name: v_edit_inp_curve gw_trg_edit_inp_curve; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_curve INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_curve FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_curve('inp_curve');


--
-- Name: v_edit_inp_curve_value gw_trg_edit_inp_curve; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_curve INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_curve_value FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_curve('inp_curve_value');


--
-- Name: v_edit_inp_dscenario_conduit gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_conduit FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('CONDUIT');


--
-- Name: v_edit_inp_dscenario_flwreg_orifice gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_flwreg_orifice FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('FLWREG-ORIFICE');


--
-- Name: v_edit_inp_dscenario_flwreg_outlet gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_flwreg_outlet FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('FLWREG-OUTLET');


--
-- Name: v_edit_inp_dscenario_flwreg_pump gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_flwreg_pump FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('FLWREG-PUMP');


--
-- Name: v_edit_inp_dscenario_flwreg_weir gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_flwreg_weir FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('FLWREG-WEIR');


--
-- Name: v_edit_inp_dscenario_inflows gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_inflows FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('INFLOWS');


--
-- Name: v_edit_inp_dscenario_inflows_poll gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_inflows_poll FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('INFLOWS-POLL');


--
-- Name: v_edit_inp_dscenario_junction gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_junction FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('JUNCTION');


--
-- Name: v_edit_inp_dscenario_lid_usage gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_lid_usage FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('LID-USAGE');


--
-- Name: v_edit_inp_dscenario_outfall gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_outfall FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('OUTFALL');


--
-- Name: v_edit_inp_dscenario_raingage gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_raingage FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('RAINGAGE');


--
-- Name: v_edit_inp_dscenario_storage gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_storage FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('STORAGE');


--
-- Name: v_edit_inp_dscenario_treatment gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_treatment FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('TREATMENT');


--
-- Name: v_edit_inp_dscenario_controls gw_trg_edit_inp_dscenario_controls; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario_controls INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_controls FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('CONTROLS');


--
-- Name: v_edit_cat_dwf_scenario gw_trg_edit_inp_dwf; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dwf INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_cat_dwf_scenario FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dwf('cat_dwf_scenario');


--
-- Name: v_edit_inp_dwf gw_trg_edit_inp_dwf; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dwf INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dwf FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dwf();


--
-- Name: v_edit_inp_flwreg_orifice gw_trg_edit_inp_flwreg; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_flwreg INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_flwreg_orifice FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_flwreg('FLWREG-ORIFICE');


--
-- Name: v_edit_inp_flwreg_outlet gw_trg_edit_inp_flwreg; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_flwreg INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_flwreg_outlet FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_flwreg('FLWREG-OUTLET');


--
-- Name: v_edit_inp_flwreg_pump gw_trg_edit_inp_flwreg; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_flwreg INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_flwreg_pump FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_flwreg('FLWREG-PUMP');


--
-- Name: v_edit_inp_flwreg_weir gw_trg_edit_inp_flwreg; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_flwreg INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_flwreg_weir FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_flwreg('FLWREG-WEIR');


--
-- Name: v_edit_inp_gully gw_trg_edit_inp_gully; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_gully INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_gully();


--
-- Name: v_edit_inp_inflows gw_trg_edit_inp_inflows; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_inflows INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_inflows FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_inflows('INFLOWS');


--
-- Name: v_edit_inp_inflows_poll gw_trg_edit_inp_inflows; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_inflows INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_inflows_poll FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_inflows('INFLOWS-POLL');


--
-- Name: v_edit_inp_divider gw_trg_edit_inp_node_divider; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_node_divider INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_divider FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_divider');


--
-- Name: v_edit_inp_junction gw_trg_edit_inp_node_junction; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_node_junction INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_junction FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_junction');


--
-- Name: v_edit_inp_netgully gw_trg_edit_inp_node_netgully; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_node_netgully INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_netgully FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_netgully');


--
-- Name: v_edit_inp_outfall gw_trg_edit_inp_node_outfall; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_node_outfall INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_outfall FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_outfall');


--
-- Name: v_edit_inp_storage gw_trg_edit_inp_node_storage; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_node_storage INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_storage FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_storage');


--
-- Name: v_edit_inp_pattern gw_trg_edit_inp_pattern; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_pattern INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_pattern FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_pattern('inp_pattern');


--
-- Name: v_edit_inp_pattern_value gw_trg_edit_inp_pattern; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_pattern INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_pattern_value FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_pattern('inp_pattern_value');


--
-- Name: v_edit_inp_subcatchment gw_trg_edit_inp_subcatchment; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_subcatchment INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_subcatchment FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_subcatchment('subcatchment');


--
-- Name: v_edit_inp_timeseries gw_trg_edit_inp_timeseries; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_timeseries INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_timeseries FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_timeseries('inp_timeseries');


--
-- Name: v_edit_inp_timeseries_value gw_trg_edit_inp_timeseries; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_timeseries INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_timeseries_value FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_timeseries('inp_timeseries_value');


--
-- Name: v_edit_inp_treatment gw_trg_edit_inp_treatment; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_treatment INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_treatment FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_treatment();


--
-- Name: v_edit_link gw_trg_edit_link; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_link INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_link FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_link();


--
-- Name: v_edit_link_connec gw_trg_edit_link; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_link INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_link_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_link();


--
-- Name: v_edit_link_gully gw_trg_edit_link; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_link INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_link_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_link();


--
-- Name: v_edit_macrodma gw_trg_edit_macrodma; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_macrodma INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_macrodma FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_macrodma('macrodma');


--
-- Name: v_edit_macrosector gw_trg_edit_macrosector; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_macrosector INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_macrosector FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_macrosector('macrosector');


--
-- Name: ve_pol_chamber gw_trg_edit_man_chamber_pol; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_man_chamber_pol INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_pol_chamber FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_man_node_pol('man_chamber_pol');


--
-- Name: v_edit_man_netelement gw_trg_edit_man_netelement; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_man_netelement INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_man_netelement FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_node('man_netelement');


--
-- Name: ve_pol_netgully gw_trg_edit_man_netgully_pol; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_man_netgully_pol INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_pol_netgully FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_man_node_pol('man_netgully_pol');


--
-- Name: ve_pol_storage gw_trg_edit_man_storage_pol; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_man_storage_pol INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_pol_storage FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_man_node_pol('man_storage_pol');


--
-- Name: ve_pol_wwtp gw_trg_edit_man_wwtp_pol; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_man_wwtp_pol INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_pol_wwtp FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_man_node_pol('man_wwtp_pol');


--
-- Name: v_edit_node gw_trg_edit_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_node INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_node FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_node('parent');


--
-- Name: v_edit_om_visit gw_trg_edit_om_visit; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_om_visit INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_om_visit FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_om_visit('om_visit');


--
-- Name: v_edit_plan_psector_x_connec gw_trg_edit_plan_psector_connec; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_plan_psector_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_plan_psector_x_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_plan_psector_x_connect('plan_psector_x_connec');


--
-- Name: v_edit_plan_psector_x_gully gw_trg_edit_plan_psector_gully; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_plan_psector_gully INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_plan_psector_x_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_plan_psector_x_connect('plan_psector_x_gully');


--
-- Name: v_ext_plot gw_trg_edit_plot; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_plot INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ext_plot FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_plot();


--
-- Name: ve_pol_connec gw_trg_edit_pol_connec; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_pol_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_pol_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_man_connec_pol();


--
-- Name: ve_pol_gully gw_trg_edit_pol_gully; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_pol_gully INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_pol_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_man_gully_pol();


--
-- Name: ve_pol_node gw_trg_edit_pol_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_pol_node INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_pol_node FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_man_node_pol();


--
-- Name: v_edit_plan_psector gw_trg_edit_psector; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_psector INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_plan_psector FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_psector('plan');


--
-- Name: v_edit_plan_psector_x_other gw_trg_edit_psector_x_other; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_psector_x_other INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_plan_psector_x_other FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_psector_x_other('plan');


--
-- Name: v_edit_raingage gw_trg_edit_raingage; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_raingage INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_raingage FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_raingage('raingage');


--
-- Name: ve_raingage gw_trg_edit_raingage; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_raingage INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_raingage FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_raingage('raingage');


--
-- Name: v_edit_review_arc gw_trg_edit_review_arc; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_review_arc INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_review_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_review_arc();


--
-- Name: v_edit_review_audit_arc gw_trg_edit_review_audit_arc; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_review_audit_arc INSTEAD OF DELETE OR UPDATE ON v_edit_review_audit_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_review_audit_arc();


--
-- Name: v_edit_review_audit_connec gw_trg_edit_review_audit_connec; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_review_audit_connec INSTEAD OF DELETE OR UPDATE ON v_edit_review_audit_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_review_audit_connec();


--
-- Name: v_edit_review_audit_gully gw_trg_edit_review_audit_gully; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_review_audit_gully INSTEAD OF DELETE OR UPDATE ON v_edit_review_audit_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_review_audit_gully();


--
-- Name: v_edit_review_audit_node gw_trg_edit_review_audit_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_review_audit_node INSTEAD OF DELETE OR UPDATE ON v_edit_review_audit_node FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_review_audit_node();


--
-- Name: v_edit_review_connec gw_trg_edit_review_connec; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_review_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_review_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_review_connec();


--
-- Name: v_edit_review_gully gw_trg_edit_review_gully; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_review_gully INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_review_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_review_gully();


--
-- Name: v_edit_review_node gw_trg_edit_review_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_review_node INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_review_node FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_review_node();


--
-- Name: v_edit_samplepoint gw_trg_edit_samplepoint; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_samplepoint INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_samplepoint FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_samplepoint('samplepoint');


--
-- Name: v_edit_sector gw_trg_edit_sector; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_sector INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_sector FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_sector('sector');


--
-- Name: v_ext_streetaxis gw_trg_edit_streetaxis; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_streetaxis INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ext_streetaxis FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_streetaxis();


--
-- Name: v_ui_om_visitman_x_gully gw_trg_edit_visitman_x_gully; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_visitman_x_gully INSTEAD OF DELETE ON v_ui_om_visitman_x_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_visitman();


--
-- Name: inp_flwreg_orifice gw_trg_flw_regulator; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_flw_regulator BEFORE INSERT OR UPDATE ON inp_flwreg_orifice FOR EACH ROW EXECUTE FUNCTION gw_trg_flw_regulator('orifice');


--
-- Name: inp_flwreg_outlet gw_trg_flw_regulator; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_flw_regulator BEFORE INSERT OR UPDATE ON inp_flwreg_outlet FOR EACH ROW EXECUTE FUNCTION gw_trg_flw_regulator('outlet');


--
-- Name: inp_flwreg_pump gw_trg_flw_regulator; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_flw_regulator BEFORE INSERT OR UPDATE ON inp_flwreg_pump FOR EACH ROW EXECUTE FUNCTION gw_trg_flw_regulator('pump');


--
-- Name: inp_flwreg_weir gw_trg_flw_regulator; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_flw_regulator BEFORE INSERT OR UPDATE ON inp_flwreg_weir FOR EACH ROW EXECUTE FUNCTION gw_trg_flw_regulator('weir');


--
-- Name: gully gw_trg_gully_proximity_insert; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_gully_proximity_insert BEFORE INSERT ON gully FOR EACH ROW EXECUTE FUNCTION gw_trg_gully_proximity();


--
-- Name: gully gw_trg_gully_proximity_update; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_gully_proximity_update AFTER UPDATE OF the_geom ON gully FOR EACH ROW EXECUTE FUNCTION gw_trg_gully_proximity();


--
-- Name: link gw_trg_link_connecrotation_update; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_link_connecrotation_update AFTER INSERT OR UPDATE OF the_geom ON link FOR EACH ROW EXECUTE FUNCTION gw_trg_link_connecrotation_update();


--
-- Name: connec gw_trg_link_data; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_link_data AFTER INSERT OR UPDATE OF expl_id2 ON connec FOR EACH ROW EXECUTE FUNCTION gw_trg_link_data('connec');


--
-- Name: gully gw_trg_link_data; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_link_data AFTER INSERT OR UPDATE OF expl_id2 ON gully FOR EACH ROW EXECUTE FUNCTION gw_trg_link_data('gully');


--
-- Name: link gw_trg_link_data; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_link_data AFTER INSERT ON link FOR EACH ROW EXECUTE FUNCTION gw_trg_link_data('link');


--
-- Name: ext_raster_dem gw_trg_manage_raster_dem_delete; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_manage_raster_dem_delete AFTER INSERT OR DELETE ON ext_raster_dem FOR EACH ROW EXECUTE FUNCTION gw_trg_manage_raster_dem();


--
-- Name: ext_raster_dem gw_trg_manage_raster_dem_insert; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_manage_raster_dem_insert BEFORE INSERT ON ext_raster_dem FOR EACH ROW EXECUTE FUNCTION gw_trg_manage_raster_dem();


--
-- Name: node gw_trg_node_arc_divide; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_node_arc_divide AFTER INSERT ON node FOR EACH ROW EXECUTE FUNCTION gw_trg_node_arc_divide();


--
-- Name: node gw_trg_node_statecontrol; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_node_statecontrol BEFORE INSERT OR UPDATE OF state ON node FOR EACH ROW EXECUTE FUNCTION gw_trg_node_statecontrol();


--
-- Name: om_visit gw_trg_om_visit; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_om_visit AFTER INSERT OR DELETE OR UPDATE OF class_id, status ON om_visit FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit();


--
-- Name: om_visit_x_arc gw_trg_om_visit; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_om_visit AFTER INSERT ON om_visit_x_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit('arc');


--
-- Name: om_visit_x_connec gw_trg_om_visit; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_om_visit AFTER INSERT ON om_visit_x_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit('connec');


--
-- Name: om_visit_x_gully gw_trg_om_visit; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_om_visit AFTER INSERT ON om_visit_x_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit('gully');


--
-- Name: om_visit_x_node gw_trg_om_visit; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_om_visit AFTER INSERT ON om_visit_x_node FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit('node');


--
-- Name: ve_visit_arc_singlevent gw_trg_om_visit_singlevent; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_om_visit_singlevent INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_visit_arc_singlevent FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit_singlevent('arc');


--
-- Name: ve_visit_connec_singlevent gw_trg_om_visit_singlevent; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_om_visit_singlevent INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_visit_connec_singlevent FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit_singlevent('connec');


--
-- Name: ve_visit_gully_singlevent gw_trg_om_visit_singlevent; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_om_visit_singlevent INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_visit_gully_singlevent FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit_singlevent('gully');


--
-- Name: ve_visit_node_singlevent gw_trg_om_visit_singlevent; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_om_visit_singlevent INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_visit_node_singlevent FOR EACH ROW EXECUTE FUNCTION gw_trg_om_visit_singlevent('node');


--
-- Name: plan_psector gw_trg_plan_psector; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector AFTER INSERT OR UPDATE OF active ON plan_psector FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector();


--
-- Name: plan_psector_x_arc gw_trg_plan_psector_delete_arc; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_delete_arc AFTER DELETE ON plan_psector_x_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_delete('arc');


--
-- Name: plan_psector_x_connec gw_trg_plan_psector_delete_connec; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_delete_connec AFTER DELETE ON plan_psector_x_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_delete('connec');


--
-- Name: plan_psector_x_gully gw_trg_plan_psector_delete_gully; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_delete_gully AFTER DELETE ON plan_psector_x_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_delete('gully');


--
-- Name: plan_psector_x_node gw_trg_plan_psector_delete_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_delete_node AFTER DELETE ON plan_psector_x_node FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_delete('node');


--
-- Name: plan_psector_x_connec gw_trg_plan_psector_link; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_link AFTER INSERT OR UPDATE OF arc_id ON plan_psector_x_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_link('connec');


--
-- Name: plan_psector_x_gully gw_trg_plan_psector_link; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_link AFTER INSERT OR UPDATE OF arc_id ON plan_psector_x_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_link('gully');


--
-- Name: plan_psector_x_arc gw_trg_plan_psector_x_arc; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_x_arc BEFORE INSERT OR UPDATE OF arc_id, state ON plan_psector_x_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_x_arc();


--
-- Name: plan_psector_x_arc gw_trg_plan_psector_x_arc_geom; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_x_arc_geom AFTER INSERT OR DELETE OR UPDATE ON plan_psector_x_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_geom('plan');


--
-- Name: plan_psector_x_connec gw_trg_plan_psector_x_connec; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_x_connec BEFORE INSERT OR UPDATE OF connec_id, state ON plan_psector_x_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_x_connec();


--
-- Name: plan_psector_x_connec gw_trg_plan_psector_x_connec_geom; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_x_connec_geom AFTER INSERT OR DELETE OR UPDATE ON plan_psector_x_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_geom('plan');


--
-- Name: plan_psector_x_gully gw_trg_plan_psector_x_gully; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_x_gully BEFORE INSERT OR UPDATE OF gully_id, state ON plan_psector_x_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_x_gully();


--
-- Name: plan_psector_x_gully gw_trg_plan_psector_x_gully_geom; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_x_gully_geom AFTER INSERT OR DELETE OR UPDATE ON plan_psector_x_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_geom('plan');


--
-- Name: plan_psector_x_node gw_trg_plan_psector_x_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_x_node BEFORE INSERT OR UPDATE OF node_id, state ON plan_psector_x_node FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_x_node();


--
-- Name: plan_psector_x_node gw_trg_plan_psector_x_node_geom; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_x_node_geom AFTER INSERT OR DELETE OR UPDATE ON plan_psector_x_node FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_geom('plan');


--
-- Name: sys_addfields gw_trg_sysaddfields; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_sysaddfields BEFORE UPDATE OF active ON sys_addfields FOR EACH ROW EXECUTE FUNCTION gw_trg_sysaddfields();


--
-- Name: arc gw_trg_topocontrol_arc; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_topocontrol_arc BEFORE INSERT OR UPDATE OF the_geom, y1, y2, elev1, elev2, custom_y1, custom_y2, custom_elev1, custom_elev2, state, inverted_slope ON arc FOR EACH ROW EXECUTE FUNCTION gw_trg_topocontrol_arc();


--
-- Name: node gw_trg_topocontrol_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_topocontrol_node AFTER INSERT OR UPDATE OF the_geom, state, top_elev, ymax, elev, custom_top_elev, custom_ymax, custom_elev ON node FOR EACH ROW EXECUTE FUNCTION gw_trg_topocontrol_node();


--
-- Name: config_typevalue gw_trg_typevalue_config_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_config_fk AFTER INSERT OR DELETE OR UPDATE ON config_typevalue FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_config_fk('config_typevalue');


--
-- Name: edit_typevalue gw_trg_typevalue_config_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_config_fk AFTER INSERT OR DELETE OR UPDATE ON edit_typevalue FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_config_fk('edit_typevalue');


--
-- Name: inp_typevalue gw_trg_typevalue_config_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_config_fk AFTER INSERT OR DELETE OR UPDATE ON inp_typevalue FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_config_fk('inp_typevalue');


--
-- Name: om_typevalue gw_trg_typevalue_config_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_config_fk AFTER INSERT OR DELETE OR UPDATE ON om_typevalue FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_config_fk('om_typevalue');


--
-- Name: plan_typevalue gw_trg_typevalue_config_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_config_fk AFTER INSERT OR DELETE OR UPDATE ON plan_typevalue FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_config_fk('plan_typevalue');


--
-- Name: sys_foreignkey gw_trg_typevalue_config_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_config_fk AFTER INSERT OR UPDATE ON sys_foreignkey FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_config_fk('sys_foreignkey');


--
-- Name: sys_typevalue gw_trg_typevalue_config_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_config_fk AFTER INSERT OR DELETE OR UPDATE ON sys_typevalue FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_config_fk('sys_typevalue');


--
-- Name: arc gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON arc FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('arc');


--
-- Name: cat_arc_shape gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON cat_arc_shape FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('cat_arc_shape');


--
-- Name: cat_dscenario gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON cat_dscenario FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('cat_dscenario');


--
-- Name: cat_hydrology gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON cat_hydrology FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('cat_hydrology');


--
-- Name: config_form_fields gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON config_form_fields FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('config_form_fields');


--
-- Name: config_form_tabs gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON config_form_tabs FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('config_form_tabs');


--
-- Name: config_info_layer gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON config_info_layer FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('config_info_layer');


--
-- Name: config_visit_class gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON config_visit_class FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('config_visit_class');


--
-- Name: config_visit_parameter gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON config_visit_parameter FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('config_visit_parameter');


--
-- Name: config_visit_parameter_action gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON config_visit_parameter_action FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('config_visit_parameter_action');


--
-- Name: connec gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON connec FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('connec');


--
-- Name: ext_cat_raster gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON ext_cat_raster FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('ext_cat_raster');


--
-- Name: gully gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON gully FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('gully');


--
-- Name: inp_buildup gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_buildup FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_buildup');


--
-- Name: inp_conduit gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_conduit FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_conduit');


--
-- Name: inp_curve gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_curve FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_curve');


--
-- Name: inp_divider gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_divider FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_divider');


--
-- Name: inp_dscenario_conduit gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_conduit FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_conduit');


--
-- Name: inp_dscenario_flwreg_orifice gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_flwreg_orifice FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_flwreg_orifice');


--
-- Name: inp_dscenario_flwreg_outlet gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_flwreg_outlet FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_flwreg_outlet');


--
-- Name: inp_dscenario_flwreg_pump gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_flwreg_pump FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_flwreg_pump');


--
-- Name: inp_dscenario_flwreg_weir gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_flwreg_weir FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_flwreg_weir');


--
-- Name: inp_dscenario_inflows_poll gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_inflows_poll FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_inflows_poll');


--
-- Name: inp_dscenario_outfall gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_outfall FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_outfall');


--
-- Name: inp_dscenario_raingage gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_raingage FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_raingage');


--
-- Name: inp_dscenario_storage gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_storage FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_storage');


--
-- Name: inp_evaporation gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_evaporation FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_evaporation');


--
-- Name: inp_files gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_files FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_files');


--
-- Name: inp_flwreg_outlet gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_flwreg_outlet FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_flwreg_outlet');


--
-- Name: inp_flwreg_pump gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_flwreg_pump FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_flwreg_pump');


--
-- Name: inp_flwreg_weir gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_flwreg_weir FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_flwreg_weir');


--
-- Name: inp_gully gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_gully');


--
-- Name: inp_inflows_poll gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_inflows_poll FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_inflows_poll');


--
-- Name: inp_lid gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_lid FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_lid');


--
-- Name: inp_lid_value gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_lid_value FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_lid_value');


--
-- Name: inp_mapunits gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_mapunits FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_mapunits');


--
-- Name: inp_netgully gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_netgully FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_netgully');


--
-- Name: inp_orifice gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_orifice FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_orifice');


--
-- Name: inp_outfall gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_outfall FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_outfall');


--
-- Name: inp_outlet gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_outlet FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_outlet');


--
-- Name: inp_pattern gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_pattern FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_pattern');


--
-- Name: inp_pollutant gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_pollutant FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_pollutant');


--
-- Name: inp_pump gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_pump FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_pump');


--
-- Name: inp_snowpack gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_snowpack FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_snowpack');


--
-- Name: inp_storage gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_storage FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_storage');


--
-- Name: inp_subcatchment gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_subcatchment FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_subcatchment');


--
-- Name: inp_temperature gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_temperature FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_temperature');


--
-- Name: inp_timeseries gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_timeseries FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_timeseries');


--
-- Name: inp_washoff gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_washoff FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_washoff');


--
-- Name: inp_weir gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_weir FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_weir');


--
-- Name: man_addfields_value gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON man_addfields_value FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('man_addfields_value');


--
-- Name: man_netgully gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON man_netgully FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('man_netgully');


--
-- Name: node gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON node FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('node');


--
-- Name: om_visit gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON om_visit FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('om_visit');


--
-- Name: plan_price gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON plan_price FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('plan_price');


--
-- Name: plan_psector gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON plan_psector FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('plan_psector');


--
-- Name: plan_result_cat gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON plan_result_cat FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('plan_result_cat');


--
-- Name: raingage gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON raingage FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('raingage');


--
-- Name: sys_addfields gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON sys_addfields FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('sys_addfields');


--
-- Name: sys_message gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON sys_message FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('sys_message');


--
-- Name: sys_table gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON sys_table FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('sys_table');


--
-- Name: v_ui_doc_x_arc gw_trg_ui_doc_x_arc; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_doc_x_arc INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_doc_x_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_doc('doc_x_arc');


--
-- Name: v_ui_doc_x_connec gw_trg_ui_doc_x_connec; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_doc_x_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_doc_x_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_doc('doc_x_connec');


--
-- Name: v_ui_doc_x_gully gw_trg_ui_doc_x_gully; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_doc_x_gully INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_doc_x_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_doc('doc_x_gully');


--
-- Name: v_ui_doc_x_node gw_trg_ui_doc_x_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_doc_x_node INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_doc_x_node FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_doc('doc_x_node');


--
-- Name: v_ui_doc_x_visit gw_trg_ui_doc_x_visit; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_doc_x_visit INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_doc_x_visit FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_doc('doc_x_visit');


--
-- Name: v_ui_element_x_arc gw_trg_ui_element; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_element INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_element_x_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_element('element_x_arc');


--
-- Name: v_ui_element_x_connec gw_trg_ui_element; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_element INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_element_x_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_element('element_x_connec');


--
-- Name: v_ui_element_x_gully gw_trg_ui_element; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_element INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_element_x_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_element('element_x_gully');


--
-- Name: v_ui_element_x_node gw_trg_ui_element; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_element INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_element_x_node FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_element('element_x_node');


--
-- Name: v_ui_event_x_arc gw_trg_ui_event_x_arc; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_event_x_arc INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_event_x_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_event('om_visit_event');


--
-- Name: v_ui_event_x_connec gw_trg_ui_event_x_connec; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_event_x_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_event_x_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_event('om_visit_event');


--
-- Name: v_ui_event_x_gully gw_trg_ui_event_x_gully; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_event_x_gully INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_event_x_gully FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_event('om_visit_event');


--
-- Name: v_ui_event_x_node gw_trg_ui_event_x_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_event_x_node INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_event_x_node FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_event('om_visit_event');


--
-- Name: v_ui_plan_psector gw_trg_ui_plan_psector; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_plan_psector INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_plan_psector FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_plan_psector();


--
-- Name: v_ui_rpt_cat_result gw_trg_ui_rpt_cat_result; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_rpt_cat_result INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ui_rpt_cat_result FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_rpt_cat_result();


--
-- Name: v_ui_om_visit gw_trg_ui_visit; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_ui_visit INSTEAD OF DELETE ON v_ui_om_visit FOR EACH ROW EXECUTE FUNCTION gw_trg_ui_visit();


--
-- Name: connec gw_trg_unique_field; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_unique_field AFTER INSERT OR UPDATE OF customer_code, state ON connec FOR EACH ROW EXECUTE FUNCTION gw_trg_unique_field('connec');


--
-- Name: vi_adjustments gw_trg_vi_adjustments; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_adjustments INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_adjustments FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_adjustments');


--
-- Name: vi_aquifers gw_trg_vi_aquifers; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_aquifers INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_aquifers FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_aquifers');


--
-- Name: vi_backdrop gw_trg_vi_backdrop; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_backdrop INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_backdrop FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_backdrop');


--
-- Name: vi_buildup gw_trg_vi_buildup; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_buildup INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_buildup FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_buildup');


--
-- Name: vi_conduits gw_trg_vi_conduits; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_conduits INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_conduits FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_conduits');


--
-- Name: vi_coordinates gw_trg_vi_coordinates; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_coordinates INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_coordinates FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_coordinates');


--
-- Name: vi_coverages gw_trg_vi_coverages; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_coverages INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_coverages FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_coverages');


--
-- Name: vi_curves gw_trg_vi_curves; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_curves INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_curves FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_curves');


--
-- Name: vi_dividers gw_trg_vi_dividers; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_dividers INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_dividers FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_dividers');


--
-- Name: vi_dwf gw_trg_vi_dwf; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_dwf INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_dwf FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_dwf');


--
-- Name: vi_evaporation gw_trg_vi_evaporation; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_evaporation INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_evaporation FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_evaporation');


--
-- Name: vi_files gw_trg_vi_files; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_files INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_files FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_files');


--
-- Name: vi_groundwater gw_trg_vi_groundwater; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_groundwater INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_groundwater FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_groundwater');


--
-- Name: vi_gwf gw_trg_vi_gwf; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_gwf INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_gwf FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_gwf');


--
-- Name: vi_controls gw_trg_vi_hydrographs; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_hydrographs INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_controls FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_controls');


--
-- Name: vi_hydrographs gw_trg_vi_hydrographs; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_hydrographs INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_hydrographs FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_hydrographs');


--
-- Name: vi_inflows gw_trg_vi_inflows; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_inflows INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_inflows FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_inflows');


--
-- Name: vi_junctions gw_trg_vi_junctions; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_junctions INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_junctions FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_junctions');


--
-- Name: vi_labels gw_trg_vi_labels; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_labels INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_labels FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_labels');


--
-- Name: vi_landuses gw_trg_vi_landuses; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_landuses INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_landuses FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_landuses');


--
-- Name: vi_lid_controls gw_trg_vi_lid_controls; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_lid_controls INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_lid_controls FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_lid_controls');


--
-- Name: vi_lid_usage gw_trg_vi_lid_usage; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_lid_usage INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_lid_usage FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_lid_usage');


--
-- Name: vi_loadings gw_trg_vi_loadings; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_loadings INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_loadings FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_loadings');


--
-- Name: vi_losses gw_trg_vi_losses; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_losses INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_losses FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_losses');


--
-- Name: vi_map gw_trg_vi_map; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_map INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_map FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_map');


--
-- Name: vi_orifices gw_trg_vi_orifices; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_orifices INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_orifices FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_orifices');


--
-- Name: vi_outfalls gw_trg_vi_outfalls; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_outfalls INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_outfalls FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_outfalls');


--
-- Name: vi_outlets gw_trg_vi_outlets; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_outlets INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_outlets FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_outlets');


--
-- Name: vi_patterns gw_trg_vi_patterns; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_patterns INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_patterns FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_patterns');


--
-- Name: vi_pollutants gw_trg_vi_pollutants; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_pollutants INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_pollutants FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_pollutants');


--
-- Name: vi_polygons gw_trg_vi_polygons; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_polygons INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_polygons FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_polygons');


--
-- Name: vi_pumps gw_trg_vi_pumps; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_pumps INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_pumps FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_pumps');


--
-- Name: vi_raingages gw_trg_vi_raingages; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_raingages INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_raingages FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_raingages');


--
-- Name: vi_rdii gw_trg_vi_rdii; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_rdii INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_rdii FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_rdii');


--
-- Name: vi_snowpacks gw_trg_vi_snowpacks; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_snowpacks INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_snowpacks FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_snowpacks');


--
-- Name: vi_storage gw_trg_vi_storage; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_storage INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_storage FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_storage');


--
-- Name: vi_subareas gw_trg_vi_subareas; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_subareas INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_subareas FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_subareas');


--
-- Name: vi_symbols gw_trg_vi_symbols; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_symbols INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_symbols FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_symbols');


--
-- Name: vi_temperature gw_trg_vi_temperature; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_temperature INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_temperature FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_temperature');


--
-- Name: vi_timeseries gw_trg_vi_timeseries; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_timeseries INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_timeseries FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_timeseries');


--
-- Name: vi_transects gw_trg_vi_transects; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_transects INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_transects FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_transects');


--
-- Name: vi_treatment gw_trg_vi_treatment; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_treatment INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_treatment FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_treatment');


--
-- Name: vi_vertices gw_trg_vi_vertices; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_vertices INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_vertices FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_vertices');


--
-- Name: vi_washoff gw_trg_vi_washoff; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_washoff INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_washoff FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_washoff');


--
-- Name: vi_weirs gw_trg_vi_weirs; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_weirs INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_weirs FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_weirs');


--
-- Name: vi_options gw_trg_vi_xsections; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_xsections INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_options FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_options');


--
-- Name: vi_report gw_trg_vi_xsections; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_xsections INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_report FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_report');


--
-- Name: vi_xsections gw_trg_vi_xsections; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_xsections INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_xsections FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_xsections');


--
-- Name: om_visit_event gw_trg_visit_event_update_xy; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_visit_event_update_xy AFTER INSERT OR UPDATE OF position_id, position_value ON om_visit_event FOR EACH ROW EXECUTE FUNCTION gw_trg_visit_event_update_xy();


--
-- Name: om_visit gw_trg_visit_expl; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_visit_expl BEFORE INSERT OR UPDATE OF the_geom ON om_visit FOR EACH ROW EXECUTE FUNCTION gw_trg_visit_expl();


ALTER TABLE config_form_fields DISABLE TRIGGER gw_trg_config_control;
ALTER TABLE config_form_fields DISABLE TRIGGER gw_trg_typevalue_fk;

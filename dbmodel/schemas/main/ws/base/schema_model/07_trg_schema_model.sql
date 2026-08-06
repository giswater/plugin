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
-- Name: doc gw_trg_doc; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_doc BEFORE INSERT ON doc FOR EACH ROW EXECUTE FUNCTION gw_trg_doc();


--
-- Name: v_ext_address gw_trg_edit_address; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_address INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ext_address FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_address();


--
-- Name: v_edit_anl_hydrant gw_trg_edit_anl_hydrant; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_anl_hydrant INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_anl_hydrant FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_anl_hydrant();


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
-- Name: v_edit_cat_feature_arc gw_trg_edit_cat_feature; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_cat_feature INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_cat_feature_arc FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_cat_feature('arc');


--
-- Name: v_edit_cat_feature_connec gw_trg_edit_cat_feature; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_cat_feature INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_cat_feature_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_cat_feature('connec');


--
-- Name: v_edit_cat_feature_node gw_trg_edit_cat_feature; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_cat_feature INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_cat_feature_node FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_cat_feature('node');


--
-- Name: cat_node gw_trg_edit_cat_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_cat_node BEFORE INSERT OR UPDATE ON cat_node FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_cat_node();


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
-- Name: v_edit_dqa gw_trg_edit_dqa; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_dqa INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_dqa FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_dqa();


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
-- Name: v_edit_field_valve gw_trg_edit_field_valve; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_field_valve INSTEAD OF UPDATE ON v_edit_field_valve FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_field_node('field_valve');


--
-- Name: arc gw_trg_edit_foreignkey; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_foreignkey AFTER DELETE OR UPDATE OF arc_id ON arc FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_foreignkey('arc_id');


--
-- Name: connec gw_trg_edit_foreignkey; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_foreignkey AFTER DELETE OR UPDATE OF connec_id ON connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_foreignkey('connec_id');


--
-- Name: node gw_trg_edit_foreignkey; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_foreignkey AFTER DELETE OR UPDATE OF node_id ON node FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_foreignkey('node_id');


--
-- Name: v_edit_inp_pipe gw_trg_edit_inp_arc_pipe; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_arc_pipe INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_pipe FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_arc('inp_pipe');


--
-- Name: v_edit_inp_virtualvalve gw_trg_edit_inp_arc_virtualvalve; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_arc_virtualvalve INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_virtualvalve FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_arc('inp_virtualvalve');


--
-- Name: v_edit_inp_connec gw_trg_edit_inp_connec; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_connec();


--
-- Name: v_edit_inp_controls gw_trg_edit_inp_controls; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_controls INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_controls FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_controls();


--
-- Name: v_edit_inp_curve gw_trg_edit_inp_curve; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_curve INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_curve FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_curve('inp_curve');


--
-- Name: v_edit_inp_curve_value gw_trg_edit_inp_curve; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_curve INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_curve_value FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_curve('inp_curve_value');


--
-- Name: v_edit_inp_dscenario_connec gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('CONNEC');


--
-- Name: v_edit_inp_dscenario_inlet gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_inlet FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('INLET');


--
-- Name: v_edit_inp_dscenario_junction gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_junction FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('JUNCTION');


--
-- Name: v_edit_inp_dscenario_pipe gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_pipe FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('PIPE');


--
-- Name: v_edit_inp_dscenario_pump gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_pump FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('PUMP');


--
-- Name: v_edit_inp_dscenario_pump_additional gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_pump_additional FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('PUMP_ADDITIONAL');


--
-- Name: v_edit_inp_dscenario_reservoir gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_reservoir FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('RESERVOIR');


--
-- Name: v_edit_inp_dscenario_tank gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_tank FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('TANK');


--
-- Name: v_edit_inp_dscenario_valve gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_valve FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('VALVE');


--
-- Name: v_edit_inp_dscenario_virtualvalve gw_trg_edit_inp_dscenario; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_virtualvalve FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('VIRTUALVALVE');


--
-- Name: v_edit_inp_dscenario_controls gw_trg_edit_inp_dscenario_controls; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario_controls INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_controls FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('CONTROLS');


--
-- Name: v_edit_inp_dscenario_demand gw_trg_edit_inp_dscenario_demand; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario_demand INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_demand FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario_demand();


--
-- Name: v_edit_inp_dscenario_rules gw_trg_edit_inp_dscenario_rules; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_dscenario_rules INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_dscenario_rules FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_dscenario('RULES');


--
-- Name: v_edit_inp_inlet gw_trg_edit_inp_node_inlet; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_node_inlet INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_inlet FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_inlet');


--
-- Name: v_edit_inp_junction gw_trg_edit_inp_node_junction; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_node_junction INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_junction FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_junction');


--
-- Name: v_edit_inp_pump gw_trg_edit_inp_node_pump; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_node_pump INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_pump FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_pump');


--
-- Name: v_edit_inp_reservoir gw_trg_edit_inp_node_reservoir; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_node_reservoir INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_reservoir FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_reservoir');


--
-- Name: v_edit_inp_shortpipe gw_trg_edit_inp_node_shortpipe; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_node_shortpipe INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_shortpipe FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_shortpipe');


--
-- Name: v_edit_inp_tank gw_trg_edit_inp_node_tank; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_node_tank INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_tank FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_tank');


--
-- Name: v_edit_inp_valve gw_trg_edit_inp_node_valve; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_node_valve INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_valve FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_valve');


--
-- Name: v_edit_inp_pattern gw_trg_edit_inp_pattern; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_pattern INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_pattern FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_pattern('inp_pattern');


--
-- Name: v_edit_inp_pattern_value gw_trg_edit_inp_pattern; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_pattern INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_pattern_value FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_pattern('inp_pattern_value');


--
-- Name: v_edit_inp_pump_additional gw_trg_edit_inp_pump_additional; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_pump_additional INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_pump_additional FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_node('inp_pump_additional');


--
-- Name: v_edit_inp_rules gw_trg_edit_inp_rules; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_inp_rules INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_inp_rules FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_inp_rules();


--
-- Name: v_edit_link gw_trg_edit_link; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_link INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_link FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_link();


--
-- Name: v_edit_macrodma gw_trg_edit_macrodma; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_macrodma INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_macrodma FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_macrodma('macrodma');


--
-- Name: v_edit_macrodqa gw_trg_edit_macrodqa; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_macrodqa INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_macrodqa FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_macrodqa('macrodqa');


--
-- Name: v_edit_macrosector gw_trg_edit_macrosector; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_macrosector INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_macrosector FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_macrosector('macrosector');


--
-- Name: ve_pol_fountain gw_trg_edit_man_fountain_pol; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_man_fountain_pol INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_pol_fountain FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_man_connec_pol('man_fountain_pol');


--
-- Name: ve_pol_register gw_trg_edit_man_register_pol; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_man_register_pol INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_pol_register FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_man_node_pol('man_register_pol');


--
-- Name: ve_pol_tank gw_trg_edit_man_tank_pol; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_man_tank_pol INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_pol_tank FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_man_node_pol('man_tank_pol');


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
-- Name: v_ext_plot gw_trg_edit_plot; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_plot INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ext_plot FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_plot();


--
-- Name: ve_pol_connec gw_trg_edit_pol_connec; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_pol_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_pol_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_man_connec_pol();


--
-- Name: ve_pol_node gw_trg_edit_pol_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_pol_node INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_pol_node FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_man_node_pol();


--
-- Name: v_edit_presszone gw_trg_edit_presszone; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_presszone INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_presszone FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_presszone();


--
-- Name: v_edit_plan_psector gw_trg_edit_psector; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_psector INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_plan_psector FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_psector('plan');


--
-- Name: v_edit_plan_psector_x_other gw_trg_edit_psector_x_other; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_psector_x_other INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_plan_psector_x_other FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_psector_x_other('plan');


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
-- Name: v_edit_review_audit_node gw_trg_edit_review_audit_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_review_audit_node INSTEAD OF DELETE OR UPDATE ON v_edit_review_audit_node FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_review_audit_node();


--
-- Name: v_edit_review_connec gw_trg_edit_review_connec; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_review_connec INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_review_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_review_connec();


--
-- Name: v_edit_review_node gw_trg_edit_review_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_review_node INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_review_node FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_review_node();

--
-- Name: v_edit_sector gw_trg_edit_sector; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_sector INSTEAD OF INSERT OR DELETE OR UPDATE ON v_edit_sector FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_sector('sector');


--
-- Name: v_ext_streetaxis gw_trg_edit_streetaxis; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_edit_streetaxis INSTEAD OF INSERT OR DELETE OR UPDATE ON v_ext_streetaxis FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_streetaxis();


--
-- Name: link gw_trg_link_connecrotation_update; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_link_connecrotation_update AFTER INSERT OR UPDATE OF the_geom ON link FOR EACH ROW EXECUTE FUNCTION gw_trg_link_connecrotation_update();


--
-- Name: connec gw_trg_link_data; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_link_data AFTER INSERT OR UPDATE OF expl_id2 ON connec FOR EACH ROW EXECUTE FUNCTION gw_trg_link_data('connec');


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
-- Name: om_mincut gw_trg_mincut; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_mincut AFTER UPDATE OF work_order, mincut_class, mincut_type, received_date, expl_id, macroexpl_id, muni_id, postcode, streetaxis_id, postnumber, anl_cause, anl_tstamp, anl_user, anl_descript, anl_feature_id, anl_feature_type, anl_the_geom, forecast_start, forecast_end, assigned_to, output ON om_mincut FOR EACH ROW EXECUTE FUNCTION gw_trg_mincut();


--
-- Name: node gw_trg_node_arc_divide; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_node_arc_divide AFTER INSERT ON node FOR EACH ROW EXECUTE FUNCTION gw_trg_node_arc_divide();


--
-- Name: node gw_trg_node_rotation_update; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_node_rotation_update AFTER INSERT OR UPDATE OF hemisphere, the_geom ON node FOR EACH ROW EXECUTE FUNCTION gw_trg_node_rotation_update();


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
-- Name: plan_psector_x_node gw_trg_plan_psector_delete_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_delete_node AFTER DELETE ON plan_psector_x_node FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_delete('node');


--
-- Name: plan_psector_x_connec gw_trg_plan_psector_link; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_link AFTER INSERT OR UPDATE OF arc_id ON plan_psector_x_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_link('connec');


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
-- Name: plan_psector_x_node gw_trg_plan_psector_x_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_x_node BEFORE INSERT OR UPDATE OF node_id, state ON plan_psector_x_node FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_x_node();


--
-- Name: plan_psector_x_node gw_trg_plan_psector_x_node_geom; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_plan_psector_x_node_geom AFTER INSERT OR DELETE OR UPDATE ON plan_psector_x_node FOR EACH ROW EXECUTE FUNCTION gw_trg_plan_psector_geom('plan');


--
-- Name: rtc_hydrometer gw_trg_rtc_hydrometer; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_rtc_hydrometer BEFORE INSERT OR DELETE OR UPDATE ON rtc_hydrometer FOR EACH ROW EXECUTE FUNCTION gw_trg_rtc_hydrometer();


--
-- Name: sys_addfields gw_trg_sysaddfields; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_sysaddfields BEFORE UPDATE OF active ON sys_addfields FOR EACH ROW EXECUTE FUNCTION gw_trg_sysaddfields();


--
-- Name: arc gw_trg_topocontrol_arc; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_topocontrol_arc BEFORE INSERT OR UPDATE OF the_geom, state ON arc FOR EACH ROW EXECUTE FUNCTION gw_trg_topocontrol_arc();


--
-- Name: node gw_trg_topocontrol_node; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_topocontrol_node AFTER INSERT OR UPDATE OF the_geom, state ON node FOR EACH ROW EXECUTE FUNCTION gw_trg_topocontrol_node();


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
-- Name: cat_dscenario gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON cat_dscenario FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('cat_dscenario');


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
-- Name: dqa gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON dqa FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('dqa');


--
-- Name: ext_cat_raster gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON ext_cat_raster FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('ext_cat_raster');


--
-- Name: inp_connec gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_connec');


--
-- Name: inp_dscenario_connec gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_connec FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_connec');


--
-- Name: inp_dscenario_demand gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_demand FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_demand');


--
-- Name: inp_dscenario_pipe gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_pipe FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_pipe');


--
-- Name: inp_dscenario_pump gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_pump FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_pump');


--
-- Name: inp_dscenario_pump_additional gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_pump_additional FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_pump_additional');


--
-- Name: inp_dscenario_shortpipe gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_shortpipe FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_shortpipe');


--
-- Name: inp_dscenario_valve gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_valve FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_valve');


--
-- Name: inp_dscenario_virtualvalve gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_dscenario_virtualvalve FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_dscenario_virtualvalve');


--
-- Name: inp_mixing gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_mixing FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_mixing');


--
-- Name: inp_pattern gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_pattern FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_pattern');


--
-- Name: inp_pipe gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_pipe FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_pipe');


--
-- Name: inp_pump gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_pump FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_pump');


--
-- Name: inp_pump_additional gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_pump_additional FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_pump_additional');


--
-- Name: inp_source gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_source FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_source');


--
-- Name: inp_times gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_times FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_times');


--
-- Name: inp_valve gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_valve FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_valve');


--
-- Name: inp_virtualvalve gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON inp_virtualvalve FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('inp_virtualvalve');


--
-- Name: man_valve gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON man_valve FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('man_valve');


--
-- Name: node gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON node FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('node');


--
-- Name: om_mincut gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON om_mincut FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('om_mincut');


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
-- Name: sector gw_trg_typevalue_fk; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_typevalue_fk AFTER INSERT OR UPDATE ON sector FOR EACH ROW EXECUTE FUNCTION gw_trg_typevalue_fk('sector');


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
-- Name: vi_backdrop gw_trg_vi_backdrop; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_backdrop INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_backdrop FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_backdrop');


--
-- Name: vi_controls gw_trg_vi_controls; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_controls INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_controls FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_controls');


--
-- Name: vi_coordinates gw_trg_vi_coordinates; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_coordinates INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_coordinates FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_coordinates');


--
-- Name: vi_curves gw_trg_vi_curves; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_curves INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_curves FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_curves');


--
-- Name: vi_demands gw_trg_vi_demands; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_demands INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_demands FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_demands');


--
-- Name: vi_emitters gw_trg_vi_emitters; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_emitters INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_emitters FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_emitters');


--
-- Name: vi_energy gw_trg_vi_energy; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_energy INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_energy FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_energy');


--
-- Name: vi_junctions gw_trg_vi_junctions; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_junctions INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_junctions FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_junctions');


--
-- Name: vi_labels gw_trg_vi_labels; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_labels INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_labels FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_labels');


--
-- Name: vi_mixing gw_trg_vi_mixing; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_mixing INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_mixing FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_mixing');


--
-- Name: vi_options gw_trg_vi_options; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_options INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_options FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_options');


--
-- Name: vi_patterns gw_trg_vi_patterns; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_patterns INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_patterns FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_patterns');


--
-- Name: vi_pipes gw_trg_vi_pipes; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_pipes INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_pipes FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_pipes');


--
-- Name: vi_pumps gw_trg_vi_pumps; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_pumps INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_pumps FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_pumps');


--
-- Name: vi_quality gw_trg_vi_quality; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_quality INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_quality FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_quality');


--
-- Name: vi_reactions gw_trg_vi_reactions; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_reactions INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_reactions FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_reactions');


--
-- Name: vi_report gw_trg_vi_report; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_report INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_report FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_report');


--
-- Name: vi_reservoirs gw_trg_vi_reservoirs; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_reservoirs INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_reservoirs FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_reservoirs');


--
-- Name: vi_rules gw_trg_vi_rules; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_rules INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_rules FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_rules');


--
-- Name: vi_sources gw_trg_vi_sources; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_sources INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_sources FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_sources');


--
-- Name: vi_status gw_trg_vi_status; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_status INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_status FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_status');


--
-- Name: vi_tags gw_trg_vi_tags; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_tags INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_tags FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_tags');


--
-- Name: vi_tanks gw_trg_vi_tanks; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_tanks INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_tanks FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_tanks');


--
-- Name: vi_times gw_trg_vi_times; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_times INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_times FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_times');


--
-- Name: vi_title gw_trg_vi_title; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_title INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_title FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_title');


--
-- Name: vi_valves gw_trg_vi_valves; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_valves INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_valves FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_valves');


--
-- Name: vi_vertices gw_trg_vi_vertices; Type: TRIGGER; Schema: Schema; Owner: -
--

CREATE TRIGGER gw_trg_vi_vertices INSTEAD OF INSERT OR DELETE OR UPDATE ON vi_vertices FOR EACH ROW EXECUTE FUNCTION gw_trg_vi('vi_vertices');


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



/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


-- FUNCTION NUMBER : 3074

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_edit_inp_dscenario()
  RETURNS trigger AS
$BODY$
DECLARE

v_dscenario_type text;

BEGIN

--Get schema name
EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

--Get view name
 v_dscenario_type = TG_ARGV[0];

  IF TG_OP = 'INSERT' THEN

		-- force selector
		INSERT INTO selector_inp_dscenario VALUES (NEW.dscenario_id, current_user) ON CONFLICT (dscenario_id, cur_user) DO NOTHING;

		IF v_dscenario_type = 'VALVE' THEN

			-- default values
			IF NEW.valve_type IS NULL OR NEW.valve_type='' THEN NEW.valve_type = (SELECT valve_type FROM ve_inp_valve WHERE node_id = NEW.node_id);END IF;
			IF NEW.setting IS NULL THEN NEW.setting = (SELECT setting FROM ve_inp_valve WHERE node_id = NEW.node_id);END IF;
			IF NEW.curve_id IS NULL OR NEW.curve_id='' THEN NEW.curve_id = (SELECT curve_id FROM ve_inp_valve WHERE node_id = NEW.node_id);END IF;
			IF NEW.minorloss IS NULL THEN NEW.minorloss = (SELECT minorloss FROM ve_inp_valve WHERE node_id = NEW.node_id);END IF;
			IF NEW.status IS NULL OR NEW.status='' THEN NEW.status = (SELECT status FROM ve_inp_valve WHERE node_id = NEW.node_id);END IF;
			IF NEW.add_settings IS NULL THEN NEW.add_settings = (SELECT add_settings FROM ve_inp_valve WHERE node_id = NEW.node_id);END IF;
			IF NEW.init_quality IS NULL THEN NEW.init_quality = (SELECT init_quality FROM ve_inp_valve WHERE node_id = NEW.node_id);END IF;
			IF NEW.head IS NULL THEN NEW.head = (SELECT head FROM ve_inp_valve WHERE node_id = NEW.node_id);END IF;
			IF NEW.pattern_id IS NULL OR NEW.pattern_id='' THEN NEW.pattern_id = (SELECT pattern_id FROM ve_inp_valve WHERE node_id = NEW.node_id);END IF;
			IF NEW.demand IS NULL THEN NEW.demand = (SELECT demand FROM ve_inp_valve WHERE node_id = NEW.node_id);END IF;
			IF NEW.demand_pattern_id IS NULL OR NEW.demand_pattern_id='' THEN NEW.demand_pattern_id = (SELECT demand_pattern_id FROM ve_inp_valve WHERE node_id = NEW.node_id);END IF;
			IF NEW.emitter_coeff IS NULL THEN NEW.emitter_coeff = (SELECT emitter_coeff FROM ve_inp_valve WHERE node_id = NEW.node_id);END IF;

			INSERT INTO inp_dscenario_valve (dscenario_id, node_id, valve_type, setting, curve_id, minorloss, status, add_settings, init_quality,
			head, pattern_id, demand, demand_pattern_id, emitter_coeff, observ)
			VALUES (NEW.dscenario_id, NEW.node_id, NEW.valve_type, NEW.setting, NEW.curve_id, NEW.minorloss, NEW.status, NEW.add_settings,
			NEW.init_quality, NEW.head, NEW.pattern_id, NEW.demand, NEW.demand_pattern_id, NEW.emitter_coeff, NEW.observ);

		ELSIF v_dscenario_type = 'TANK' THEN

			-- default values
			IF NEW.initlevel IS NULL THEN NEW.initlevel = (SELECT initlevel FROM ve_inp_tank WHERE node_id = NEW.node_id);END IF;
			IF NEW.minlevel IS NULL THEN NEW.minlevel = (SELECT minlevel FROM ve_inp_tank WHERE node_id = NEW.node_id);END IF;
			IF NEW.maxlevel IS NULL THEN NEW.maxlevel = (SELECT maxlevel FROM ve_inp_tank WHERE node_id = NEW.node_id);END IF;
			IF NEW.diameter IS NULL THEN NEW.diameter = (SELECT diameter FROM ve_inp_tank WHERE node_id = NEW.node_id);END IF;
			IF NEW.minvol IS NULL THEN NEW.minvol = (SELECT minvol FROM ve_inp_tank WHERE node_id = NEW.node_id);END IF;
			IF NEW.curve_id IS NULL OR NEW.curve_id='' THEN NEW.curve_id = (SELECT curve_id FROM ve_inp_tank WHERE node_id = NEW.node_id);END IF;
			IF NEW.overflow IS NULL OR NEW.overflow='' THEN NEW.overflow = (SELECT overflow FROM ve_inp_tank WHERE node_id = NEW.node_id);END IF;

			IF NEW.mixing_model IS NULL OR NEW.mixing_model='' THEN NEW.mixing_model = (SELECT mixing_model FROM ve_inp_tank WHERE node_id = NEW.node_id);END IF;
			IF NEW.mixing_fraction IS NULL THEN NEW.mixing_fraction = (SELECT mixing_fraction FROM ve_inp_tank WHERE node_id = NEW.node_id);END IF;
			IF NEW.reaction_coeff IS NULL THEN NEW.reaction_coeff = (SELECT reaction_coeff FROM ve_inp_tank WHERE node_id = NEW.node_id);END IF;
			IF NEW.init_quality IS NULL THEN NEW.init_quality = (SELECT init_quality FROM ve_inp_tank WHERE node_id = NEW.node_id);END IF;
			IF NEW.source_type IS NULL OR NEW.source_type='' THEN NEW.source_type = (SELECT source_type FROM ve_inp_tank WHERE node_id = NEW.node_id);END IF;
			IF NEW.source_quality IS NULL THEN NEW.source_quality = (SELECT source_quality FROM ve_inp_tank WHERE node_id = NEW.node_id);END IF;
			IF NEW.source_pattern_id IS NULL OR NEW.source_pattern_id='' THEN NEW.source_pattern_id = (SELECT source_pattern_id FROM ve_inp_tank WHERE node_id = NEW.node_id);END IF;

			INSERT INTO inp_dscenario_tank (dscenario_id, node_id, initlevel, minlevel, maxlevel, diameter, minvol, curve_id, overflow,
			mixing_model, mixing_fraction, reaction_coeff, init_quality, source_type, source_quality, source_pattern_id, observ)
			VALUES (NEW.dscenario_id, NEW.node_id, NEW.initlevel, NEW.minlevel, NEW.maxlevel, NEW.diameter, NEW.minvol, NEW.curve_id, NEW.overflow,
			NEW.mixing_model, NEW.mixing_fraction, NEW.reaction_coeff, NEW.init_quality, NEW.source_type, NEW.source_quality, NEW.source_pattern_id, NEW.observ);

		ELSIF v_dscenario_type = 'SHORTPIPE' THEN

			-- default values
			IF NEW.minorloss IS NULL THEN NEW.minorloss = (SELECT minorloss FROM ve_inp_shortpipe WHERE node_id = NEW.node_id);END IF;
			IF NEW.status IS NULL OR NEW.status='' THEN
				NEW.status = (SELECT CASE WHEN closed = false THEN 'CLOSED' WHEN closed = true THEN 'OPEN' END FROM man_valve WHERE node_id = NEW.node_id);
			END IF;

			IF NEW.bulk_coeff IS NULL THEN NEW.bulk_coeff = (SELECT bulk_coeff FROM ve_inp_shortpipe WHERE node_id = NEW.node_id);END IF;
			IF NEW.wall_coeff IS NULL THEN NEW.wall_coeff = (SELECT wall_coeff FROM ve_inp_shortpipe WHERE node_id = NEW.node_id);END IF;
			IF NEW.to_arc IS NULL THEN NEW.to_arc = (SELECT to_arc FROM man_valve WHERE node_id = NEW.node_id);END IF;
			IF NEW.head IS NULL THEN NEW.head = (SELECT head FROM ve_inp_shortpipe WHERE node_id = NEW.node_id);END IF;
			IF NEW.pattern_id IS NULL OR NEW.pattern_id='' THEN NEW.pattern_id = (SELECT pattern_id FROM ve_inp_shortpipe WHERE node_id = NEW.node_id);END IF;
			IF NEW.demand IS NULL THEN NEW.demand = (SELECT demand FROM ve_inp_shortpipe WHERE node_id = NEW.node_id);END IF;
			IF NEW.demand_pattern_id IS NULL OR NEW.demand_pattern_id='' THEN NEW.demand_pattern_id = (SELECT demand_pattern_id FROM ve_inp_shortpipe WHERE node_id = NEW.node_id);END IF;
			IF NEW.emitter_coeff IS NULL THEN NEW.emitter_coeff = (SELECT emitter_coeff FROM ve_inp_shortpipe WHERE node_id = NEW.node_id);END IF;

			INSERT INTO inp_dscenario_shortpipe(dscenario_id, node_id, minorloss, status, bulk_coeff, wall_coeff, to_arc, head, pattern_id, demand, demand_pattern_id, emitter_coeff, observ)
			VALUES (NEW.dscenario_id, NEW.node_id, NEW.minorloss, NEW.status, NEW.bulk_coeff, NEW.wall_coeff, NEW.to_arc, NEW.head, NEW.pattern_id, NEW.demand, NEW.demand_pattern_id, NEW.emitter_coeff, NEW.observ);

		ELSIF v_dscenario_type = 'RESERVOIR' THEN

			-- default values
			IF NEW.pattern_id IS NULL OR NEW.pattern_id='' THEN NEW.pattern_id = (SELECT pattern_id FROM ve_inp_reservoir WHERE node_id = NEW.node_id);END IF;
			IF NEW.head IS NULL THEN NEW.head = (SELECT head FROM ve_inp_reservoir WHERE node_id = NEW.node_id);END IF;
			IF NEW.init_quality IS NULL THEN NEW.init_quality = (SELECT init_quality FROM ve_inp_reservoir WHERE node_id = NEW.node_id);END IF;
			IF NEW.source_type IS NULL OR NEW.source_type='' THEN NEW.source_type = (SELECT source_type FROM ve_inp_reservoir WHERE node_id = NEW.node_id);END IF;
			IF NEW.source_quality IS NULL THEN NEW.source_quality = (SELECT source_quality FROM ve_inp_reservoir WHERE node_id = NEW.node_id);END IF;
			IF NEW.source_pattern_id IS NULL OR NEW.source_pattern_id='' THEN NEW.source_pattern_id = (SELECT source_pattern_id FROM ve_inp_reservoir WHERE node_id = NEW.node_id);END IF;

			INSERT INTO inp_dscenario_reservoir(dscenario_id, node_id, pattern_id, head, init_quality, source_type, source_quality, source_pattern_id, observ)
			VALUES (NEW.dscenario_id, NEW.node_id, NEW.pattern_id, NEW.head, NEW.init_quality, NEW.source_type, NEW.source_quality, NEW.source_pattern_id, NEW.observ);

		ELSIF v_dscenario_type = 'PUMP' THEN

			-- default values
			IF NEW.power IS NULL THEN NEW.power = (SELECT power FROM ve_inp_pump WHERE node_id = NEW.node_id);END IF;
			IF NEW.curve_id IS NULL OR NEW.curve_id='' THEN NEW.curve_id = (SELECT curve_id FROM ve_inp_pump WHERE node_id = NEW.node_id);END IF;
			IF NEW.pattern_id IS NULL OR NEW.pattern_id='' THEN NEW.pattern_id = (SELECT pattern_id FROM ve_inp_pump WHERE node_id = NEW.node_id);END IF;
			IF NEW.status IS NULL OR NEW.status='' THEN NEW.status = (SELECT status FROM ve_inp_pump WHERE node_id = NEW.node_id);END IF;

			IF NEW.effic_curve_id IS NULL OR NEW.effic_curve_id='' THEN NEW.effic_curve_id = (SELECT effic_curve_id FROM ve_inp_pump WHERE node_id = NEW.node_id);END IF;
			IF NEW.energy_price IS NULL THEN NEW.energy_price = (SELECT energy_price FROM ve_inp_pump WHERE node_id = NEW.node_id);END IF;
			IF NEW.energy_pattern_id IS NULL OR NEW.energy_pattern_id='' THEN NEW.energy_pattern_id = (SELECT energy_pattern_id FROM ve_inp_pump WHERE node_id = NEW.node_id);END IF;

			INSERT INTO inp_dscenario_pump(dscenario_id, node_id, power, curve_id, speed, pattern_id, status, effic_curve_id, energy_price, energy_pattern_id, observ)
			VALUES (NEW.dscenario_id, NEW.node_id, NEW.power, NEW.curve_id, NEW.speed, NEW.pattern_id, NEW.status, NEW.effic_curve_id, NEW.energy_price, NEW.energy_pattern_id, NEW.observ);


		ELSIF v_dscenario_type = 'VIRTUALPUMP' THEN

			-- default values
			IF NEW.power IS NULL THEN NEW.power = (SELECT power FROM ve_inp_virtualpump WHERE arc_id = NEW.arc_id);END IF;
			IF NEW.curve_id IS NULL OR NEW.curve_id='' THEN NEW.curve_id = (SELECT curve_id FROM ve_inp_virtualpump WHERE arc_id = NEW.arc_id);END IF;
			IF NEW.pattern_id IS NULL OR NEW.pattern_id='' THEN NEW.pattern_id = (SELECT pattern_id FROM ve_inp_virtualpump WHERE arc_id = NEW.arc_id);END IF;
			IF NEW.status IS NULL OR NEW.status='' THEN NEW.status = (SELECT status FROM ve_inp_virtualpump WHERE arc_id = NEW.arc_id);END IF;

			IF NEW.effic_curve_id IS NULL OR NEW.effic_curve_id='' THEN NEW.effic_curve_id = (SELECT effic_curve_id FROM ve_inp_virtualpump WHERE arc_id = NEW.arc_id);END IF;
			IF NEW.energy_price IS NULL THEN NEW.energy_price = (SELECT energy_price FROM ve_inp_virtualpump WHERE arc_id = NEW.arc_id);END IF;
			IF NEW.energy_pattern_id IS NULL OR NEW.energy_pattern_id='' THEN NEW.energy_pattern_id = (SELECT energy_pattern_id FROM ve_inp_virtualpump WHERE arc_id = NEW.arc_id);END IF;

			INSERT INTO inp_dscenario_virtualpump(dscenario_id, arc_id, power, curve_id, speed, pattern_id, status, effic_curve_id, energy_price, energy_pattern_id, observ)
			VALUES (NEW.dscenario_id, NEW.arc_id, NEW.power, NEW.curve_id, NEW.speed, NEW.pattern_id, NEW.status, NEW.effic_curve_id, NEW.energy_price, NEW.energy_pattern_id, NEW.observ);

		ELSIF v_dscenario_type = 'PIPE' THEN

			-- default values
			IF NEW.minorloss IS NULL THEN NEW.minorloss = (SELECT minorloss FROM ve_inp_pipe WHERE arc_id = NEW.arc_id);END IF;
			IF NEW.status IS NULL OR NEW.status='' THEN NEW.status = (SELECT status FROM ve_inp_pipe WHERE arc_id = NEW.arc_id);END IF;
			IF NEW.roughness IS NULL THEN NEW.roughness = (SELECT roughness FROM temp_arc WHERE arc_id = NEW.arc_id::text);END IF;
			IF NEW.dint IS NULL THEN NEW.dint = (SELECT diameter FROM temp_arc WHERE arc_id = NEW.arc_id::text);END IF;

			IF NEW.bulk_coeff IS NULL THEN NEW.bulk_coeff = (SELECT bulk_coeff FROM ve_inp_pipe WHERE arc_id = NEW.arc_id);END IF;
			IF NEW.wall_coeff IS NULL THEN NEW.wall_coeff = (SELECT wall_coeff FROM ve_inp_pipe WHERE arc_id = NEW.arc_id);END IF;


			INSERT INTO inp_dscenario_pipe(dscenario_id, arc_id, minorloss, status, roughness, dint, bulk_coeff, wall_coeff, observ)
			VALUES (NEW.dscenario_id, NEW.arc_id, NEW.minorloss, NEW.status, NEW.roughness, NEW.dint, NEW.bulk_coeff, NEW.wall_coeff, NEW.observ);

		ELSIF v_dscenario_type = 'JUNCTION' THEN

			-- default values
			IF NEW.demand IS NULL THEN NEW.demand = (SELECT demand FROM ve_inp_junction WHERE node_id = NEW.node_id);END IF;
			IF NEW.pattern_id IS NULL OR NEW.pattern_id='' THEN NEW.pattern_id = (SELECT pattern_id FROM ve_inp_junction WHERE node_id = NEW.node_id);END IF;

			IF NEW.init_quality IS NULL THEN NEW.init_quality = (SELECT init_quality FROM ve_inp_junction WHERE node_id = NEW.node_id);END IF;
			IF NEW.source_type IS NULL OR NEW.source_type='' THEN NEW.source_type = (SELECT source_type FROM ve_inp_junction WHERE node_id = NEW.node_id);END IF;
			IF NEW.source_quality IS NULL THEN NEW.source_quality = (SELECT source_quality FROM ve_inp_junction WHERE node_id = NEW.node_id);END IF;
			IF NEW.source_pattern_id IS NULL OR NEW.source_pattern_id='' THEN NEW.source_pattern_id = (SELECT source_pattern_id FROM ve_inp_junction WHERE node_id = NEW.node_id);END IF;

			INSERT INTO inp_dscenario_junction(dscenario_id, node_id, demand, pattern_id, init_quality, source_type, source_quality, source_pattern_id, emitter_coeff, observ)
			VALUES (NEW.dscenario_id, NEW.node_id, NEW.demand, NEW.pattern_id, NEW.init_quality, NEW.source_type, NEW.source_quality, NEW.source_pattern_id, NEW.emitter_coeff, NEW.observ);

		ELSIF v_dscenario_type = 'CONNEC' THEN

			-- default values
			IF NEW.demand IS NULL THEN NEW.demand = (SELECT demand FROM ve_inp_connec WHERE connec_id = NEW.connec_id);END IF;
			IF NEW.pattern_id IS NULL OR NEW.pattern_id='' THEN NEW.pattern_id = (SELECT pattern_id FROM ve_inp_connec WHERE connec_id = NEW.connec_id);END IF;
			IF NEW.custom_roughness IS NULL THEN NEW.custom_roughness = (SELECT custom_roughness FROM ve_inp_connec WHERE connec_id = NEW.connec_id);END IF;
			IF NEW.custom_length IS NULL THEN NEW.custom_length = (SELECT custom_length FROM ve_inp_connec WHERE connec_id = NEW.connec_id);END IF;
			IF NEW.custom_dint IS NULL THEN NEW.custom_dint = (SELECT custom_dint FROM ve_inp_connec WHERE connec_id = NEW.connec_id);END IF;

			IF NEW.init_quality IS NULL THEN NEW.init_quality = (SELECT init_quality FROM ve_inp_connec WHERE connec_id = NEW.connec_id);END IF;
			IF NEW.source_type IS NULL OR NEW.source_type='' THEN NEW.source_type = (SELECT source_type FROM ve_inp_connec WHERE connec_id = NEW.connec_id);END IF;
			IF NEW.source_quality IS NULL THEN NEW.source_quality = (SELECT source_quality FROM ve_inp_connec WHERE connec_id = NEW.connec_id);END IF;
			IF NEW.source_pattern_id IS NULL OR NEW.source_pattern_id='' THEN NEW.source_pattern_id = (SELECT source_pattern_id FROM ve_inp_connec WHERE connec_id = NEW.connec_id);END IF;

			INSERT INTO inp_dscenario_connec(dscenario_id, connec_id, demand, pattern_id, custom_roughness, custom_length, custom_dint, init_quality, source_type, source_quality, source_pattern_id, observ)
			VALUES (NEW.dscenario_id, NEW.connec_id, NEW.demand, NEW.pattern_id, NEW.custom_roughness, NEW.custom_length, NEW.custom_dint
			, NEW.init_quality, NEW.source_type, NEW.source_quality, NEW.source_pattern_id, NEW.observ);

		ELSIF v_dscenario_type = 'INLET' THEN

			-- default values
			IF NEW.initlevel IS NULL THEN NEW.initlevel = (SELECT initlevel FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.minlevel IS NULL THEN NEW.minlevel = (SELECT minlevel FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.maxlevel IS NULL THEN NEW.maxlevel = (SELECT maxlevel FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.diameter IS NULL THEN NEW.diameter = (SELECT diameter FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.minvol IS NULL THEN NEW.minvol = (SELECT minvol FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.curve_id IS NULL OR NEW.curve_id='' THEN NEW.curve_id = (SELECT curve_id FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.overflow IS NULL OR NEW.overflow='' THEN NEW.overflow = (SELECT overflow FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.pattern_id IS NULL OR NEW.pattern_id='' THEN NEW.pattern_id = (SELECT pattern_id FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.head IS NULL THEN NEW.head = (SELECT head FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;

			IF NEW.mixing_model IS NULL OR NEW.mixing_model='' THEN NEW.mixing_model = (SELECT mixing_model FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.mixing_fraction IS NULL THEN NEW.mixing_fraction = (SELECT mixing_fraction FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.reaction_coeff IS NULL THEN NEW.reaction_coeff = (SELECT reaction_coeff FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.init_quality IS NULL THEN NEW.init_quality = (SELECT init_quality FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.source_type IS NULL OR NEW.source_type='' THEN NEW.source_type = (SELECT source_type FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.source_quality IS NULL THEN NEW.source_quality = (SELECT source_quality FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.source_pattern_id IS NULL OR NEW.source_pattern_id='' THEN NEW.source_pattern_id = (SELECT source_pattern_id FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.demand IS NULL THEN NEW.demand = (SELECT demand FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.demand_pattern_id IS NULL OR NEW.demand_pattern_id='' THEN NEW.demand_pattern_id = (SELECT source_pattern_id FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;
			IF NEW.emitter_coeff IS NULL THEN NEW.emitter_coeff = (SELECT emitter_coeff FROM ve_inp_inlet WHERE node_id = NEW.node_id);END IF;

			INSERT INTO inp_dscenario_inlet (dscenario_id, node_id, initlevel, minlevel, maxlevel, diameter, minvol, curve_id, overflow, pattern_id, head,
			mixing_model, mixing_fraction, reaction_coeff, init_quality, source_type, source_quality, source_pattern_id, demand, demand_pattern_id, emitter_coeff, observ)
			VALUES (NEW.dscenario_id, NEW.node_id, NEW.initlevel, NEW.minlevel, NEW.maxlevel, NEW.diameter, NEW.minvol, NEW.curve_id, NEW.overflow, NEW.pattern_id, NEW.head,
			NEW.mixing_model, NEW.mixing_fraction, NEW.reaction_coeff, NEW.init_quality, NEW.source_type, NEW.source_quality, NEW.source_pattern_id, NEW.demand, NEW.demand_pattern_id, NEW.emitter_coeff, NEW.observ);

		ELSIF v_dscenario_type = 'VIRTUALVALVE' THEN

			-- default values
			IF NEW.valve_type IS NULL OR NEW.valve_type='' THEN NEW.valve_type = (SELECT valve_type FROM ve_inp_virtualvalve WHERE arc_id = NEW.arc_id);END IF;
			IF NEW.setting IS NULL THEN NEW.setting = (SELECT setting FROM ve_inp_virtualvalve WHERE arc_id = NEW.arc_id);END IF;
			IF NEW.curve_id IS NULL OR NEW.curve_id='' THEN NEW.curve_id = (SELECT curve_id FROM ve_inp_virtualvalve WHERE arc_id = NEW.arc_id);END IF;
			IF NEW.minorloss IS NULL THEN NEW.minorloss = (SELECT minorloss FROM ve_inp_virtualvalve WHERE arc_id = NEW.arc_id);END IF;
			IF NEW.status IS NULL OR NEW.status='' THEN NEW.status = (SELECT status FROM ve_inp_virtualvalve WHERE arc_id = NEW.arc_id);END IF;
			IF NEW.init_quality IS NULL THEN NEW.init_quality = (SELECT init_quality FROM ve_inp_virtualvalve WHERE arc_id = NEW.arc_id);END IF;

			INSERT INTO inp_dscenario_virtualvalve (dscenario_id, arc_id, valve_type, setting, curve_id, minorloss, status, init_quality, observ)
			VALUES (NEW.dscenario_id, NEW.arc_id, NEW.valve_type, NEW.setting, NEW.curve_id, NEW.minorloss, NEW.status, NEW.init_quality, NEW.observ);

		ELSIF v_dscenario_type = 'FLWREG-PUMP' THEN

			-- default values
			IF NEW.power IS NULL THEN NEW.power = (SELECT power FROM ve_inp_frpump WHERE element_id = NEW.element_id);END IF;
			IF NEW.curve_id IS NULL OR NEW.curve_id='' THEN NEW.curve_id = (SELECT curve_id FROM ve_inp_frpump WHERE element_id = NEW.element_id);END IF;
			IF NEW.speed IS NULL THEN NEW.speed = (SELECT speed FROM ve_inp_frpump WHERE element_id = NEW.element_id);END IF;
			IF NEW.pattern_id IS NULL OR NEW.pattern_id='' THEN NEW.pattern_id = (SELECT pattern_id FROM ve_inp_frpump WHERE element_id = NEW.element_id);END IF;
			IF NEW.status IS NULL OR NEW.status='' THEN NEW.status = (SELECT status FROM ve_inp_frpump WHERE element_id = NEW.element_id);END IF;
			IF NEW.effic_curve_id IS NULL OR NEW.effic_curve_id='' THEN NEW.effic_curve_id = (SELECT effic_curve_id FROM ve_inp_frpump WHERE element_id = NEW.element_id);END IF;
			IF NEW.energy_price IS NULL THEN NEW.energy_price = (SELECT energy_price FROM ve_inp_frpump WHERE element_id = NEW.element_id);END IF;
			IF NEW.energy_pattern_id IS NULL OR NEW.energy_pattern_id='' THEN NEW.energy_pattern_id = (SELECT energy_pattern_id FROM ve_inp_frpump WHERE element_id = NEW.element_id);END IF;

			INSERT INTO inp_dscenario_frpump(dscenario_id, element_id, power, curve_id, speed, pattern_id, status, effic_curve_id, energy_price, energy_pattern_id, observ)
			VALUES (NEW.dscenario_id, NEW.element_id, NEW.power, NEW.curve_id, NEW.speed, NEW.pattern_id, NEW.status, NEW.effic_curve_id, NEW.energy_price, NEW.energy_pattern_id, NEW.observ);

		ELSIF v_dscenario_type = 'FLWREG-VALVE' THEN

			-- default values
			IF NEW.valve_type IS NULL OR NEW.valve_type='' THEN NEW.valve_type = (SELECT valve_type FROM ve_inp_frvalve WHERE element_id = NEW.element_id);END IF;
			IF NEW.custom_dint IS NULL THEN NEW.custom_dint = (SELECT custom_dint FROM ve_inp_frvalve WHERE element_id = NEW.element_id);END IF;
			IF NEW.setting IS NULL THEN NEW.setting = (SELECT setting FROM ve_inp_frvalve WHERE element_id = NEW.element_id);END IF;
			IF NEW.curve_id IS NULL OR NEW.curve_id='' THEN NEW.curve_id = (SELECT curve_id FROM ve_inp_frvalve WHERE element_id = NEW.element_id);END IF;
			IF NEW.minorloss IS NULL THEN NEW.minorloss = (SELECT minorloss FROM ve_inp_frvalve WHERE element_id = NEW.element_id);END IF;
			IF NEW.add_settings IS NULL THEN NEW.add_settings = (SELECT add_settings FROM ve_inp_frvalve WHERE element_id = NEW.element_id);END IF;
			IF NEW.init_quality IS NULL THEN NEW.init_quality = (SELECT init_quality FROM ve_inp_frvalve WHERE element_id = NEW.element_id);END IF;

			INSERT INTO inp_dscenario_frvalve (dscenario_id, element_id, valve_type, custom_dint, setting, curve_id, minorloss, add_settings, init_quality, observ)
			VALUES (NEW.dscenario_id, NEW.element_id, NEW.valve_type, NEW.custom_dint, NEW.setting, NEW.curve_id, NEW.minorloss, NEW.add_settings, NEW.init_quality, NEW.observ);

		ELSIF v_dscenario_type = 'FLWREG-SHORTPIPE' THEN

			-- default values
			IF NEW.minorloss IS NULL THEN NEW.minorloss = (SELECT minorloss FROM ve_inp_frshortpipe WHERE element_id = NEW.element_id);END IF;
			IF NEW.status IS NULL OR NEW.status='' THEN NEW.status = (SELECT status FROM ve_inp_frshortpipe WHERE element_id = NEW.element_id);END IF;
			IF NEW.bulk_coeff IS NULL THEN NEW.bulk_coeff = (SELECT bulk_coeff FROM ve_inp_frshortpipe WHERE element_id = NEW.element_id);END IF;
			IF NEW.wall_coeff IS NULL THEN NEW.wall_coeff = (SELECT wall_coeff FROM ve_inp_frshortpipe WHERE element_id = NEW.element_id);END IF;
			IF NEW.custom_dint IS NULL THEN NEW.custom_dint = (SELECT custom_dint FROM ve_inp_frshortpipe WHERE element_id = NEW.element_id);END IF;

			INSERT INTO inp_dscenario_frshortpipe(dscenario_id, element_id, minorloss, status, bulk_coeff, wall_coeff, custom_dint, observ)
			VALUES (NEW.dscenario_id, NEW.element_id, NEW.minorloss, NEW.status, NEW.bulk_coeff, NEW.wall_coeff, NEW.custom_dint, NEW.observ);

		ELSIF v_dscenario_type = 'RULES' THEN
			INSERT INTO inp_dscenario_rules(dscenario_id, sector_id, text, active, observ)
			VALUES (NEW.dscenario_id, NEW.sector_id, NEW.text, NEW.active, NEW.observ);

		ELSIF v_dscenario_type = 'CONTROLS' THEN
			INSERT INTO inp_dscenario_controls(dscenario_id, sector_id, text, active, observ)
			VALUES (NEW.dscenario_id, NEW.sector_id, NEW.text, NEW.active, NEW.observ);

		ELSIF v_dscenario_type = 'PATTERN' THEN
			INSERT INTO inp_dscenario_pattern(dscenario_id, pattern_id, pattern_type, observ, tscode, tsparameters, expl_id, log, active)
			SELECT NEW.dscenario_id, NEW.pattern_id, pattern_type, observ, tscode, tsparameters::json, expl_id, log, active FROM ve_inp_pattern WHERE pattern_id = NEW.pattern_id;

			INSERT INTO inp_dscenario_pattern_value(dscenario_id, pattern_id, factor_1, factor_2, factor_3, factor_4, factor_5, factor_6, factor_7, factor_8, factor_9, factor_10, factor_11, factor_12, factor_13, factor_14, factor_15, factor_16, factor_17, factor_18)
			SELECT NEW.dscenario_id, NEW.pattern_id, factor_1, factor_2, factor_3, factor_4, factor_5, factor_6, factor_7, factor_8, factor_9, factor_10, factor_11, factor_12, factor_13, factor_14, factor_15, factor_16, factor_17, factor_18 FROM ve_inp_pattern_value WHERE pattern_id = NEW.pattern_id;

		ELSIF v_dscenario_type = 'PATTERN_VALUE' THEN
			INSERT INTO inp_dscenario_pattern_value(dscenario_id, pattern_id, factor_1, factor_2, factor_3, factor_4, factor_5, factor_6, factor_7, factor_8, factor_9, factor_10, factor_11, factor_12, factor_13, factor_14, factor_15, factor_16, factor_17, factor_18)
			VALUES (NEW.dscenario_id, NEW.pattern_id, NEW.factor_1, NEW.factor_2, NEW.factor_3, NEW.factor_4, NEW.factor_5, NEW.factor_6, NEW.factor_7, NEW.factor_8, NEW.factor_9, NEW.factor_10, NEW.factor_11, NEW.factor_12, NEW.factor_13, NEW.factor_14, NEW.factor_15, NEW.factor_16, NEW.factor_17, NEW.factor_18);
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'UPDATE' THEN

		IF v_dscenario_type = 'VALVE' THEN
			UPDATE inp_dscenario_valve SET dscenario_id=NEW.dscenario_id, node_id=NEW.node_id, valve_type=NEW.valve_type, setting=NEW.setting,
			curve_id=NEW.curve_id, minorloss=NEW.minorloss, status=NEW.status, add_settings=NEW.add_settings,
			init_quality=NEW.init_quality, head = NEW.head, pattern_id = NEW.pattern_id, demand = NEW.demand, demand_pattern_id = NEW.demand_pattern_id, emitter_coeff = NEW.emitter_coeff,
			observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND node_id=OLD.node_id;

		ELSIF v_dscenario_type = 'TANK' THEN
			UPDATE inp_dscenario_tank SET dscenario_id=NEW.dscenario_id, node_id=NEW.node_id, initlevel=NEW.initlevel, minlevel=NEW.minlevel,
			maxlevel=NEW.maxlevel, 	diameter=NEW.diameter, minvol=NEW.minvol, curve_id=NEW.curve_id, overflow=NEW.overflow,
			mixing_model=NEW.mixing_model, mixing_fraction=NEW.mixing_fraction, reaction_coeff=NEW.reaction_coeff,  init_quality=NEW.init_quality, source_type=NEW.source_type,
			source_quality=NEW.source_quality, source_pattern_id=NEW.source_pattern_id, observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND node_id=OLD.node_id;

		ELSIF v_dscenario_type = 'SHORTPIPE' THEN
			UPDATE inp_dscenario_shortpipe SET dscenario_id=NEW.dscenario_id, node_id=NEW.node_id, minorloss=NEW.minorloss, status=NEW.status,
			bulk_coeff = NEW.bulk_coeff, wall_coeff = NEW.wall_coeff, to_arc = NEW.to_arc, head = NEW.head, pattern_id = NEW.pattern_id, demand = NEW.demand, 
			demand_pattern_id = NEW.demand_pattern_id, emitter_coeff = NEW.emitter_coeff, observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND node_id=OLD.node_id;

		ELSIF v_dscenario_type = 'RESERVOIR' THEN
			UPDATE inp_dscenario_reservoir SET dscenario_id=NEW.dscenario_id, node_id=NEW.node_id, pattern_id=NEW.pattern_id, head=NEW.head,
			init_quality=NEW.init_quality, source_type=NEW.source_type, source_quality=NEW.source_quality, source_pattern_id=NEW.source_pattern_id, observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND node_id=OLD.node_id;

		ELSIF v_dscenario_type = 'PUMP' THEN
			UPDATE inp_dscenario_pump SET dscenario_id=NEW.dscenario_id, node_id=NEW.node_id, power=NEW.power, curve_id=NEW.curve_id,
			speed=NEW.speed, pattern_id=NEW.pattern_id, status=NEW.status,
			effic_curve_id = NEW.effic_curve_id, energy_price = NEW.energy_price, energy_pattern_id = NEW.energy_pattern_id, observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND node_id=OLD.node_id;

		ELSIF v_dscenario_type = 'PIPE' THEN
			UPDATE inp_dscenario_pipe SET dscenario_id=NEW.dscenario_id, arc_id=NEW.arc_id, minorloss=NEW.minorloss, status=NEW.status,
			roughness=NEW.roughness, dint=NEW.dint,
			bulk_coeff=NEW.bulk_coeff, wall_coeff = NEW.wall_coeff, observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND arc_id=OLD.arc_id;

		ELSIF v_dscenario_type = 'JUNCTION' THEN
			UPDATE inp_dscenario_junction SET dscenario_id=NEW.dscenario_id, node_id=NEW.node_id, demand=NEW.demand, pattern_id=NEW.pattern_id,
			emitter_coeff=NEW.emitter_coeff, init_quality=NEW.init_quality, source_type=NEW.source_type, source_quality=NEW.source_quality, source_pattern_id=NEW.source_pattern_id, observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND node_id=OLD.node_id;

		ELSIF v_dscenario_type = 'CONNEC' THEN
			UPDATE inp_dscenario_connec SET dscenario_id=NEW.dscenario_id, connec_id=NEW.connec_id,
			demand=NEW.demand, pattern_id=NEW.pattern_id, peak_factor=NEW.peak_factor,
			custom_roughness=NEW.custom_roughness, custom_length=NEW.custom_length, custom_dint=NEW.custom_dint,
			emitter_coeff=NEW.emitter_coeff, init_quality=NEW.init_quality, source_type=NEW.source_type, source_quality=NEW.source_quality, source_pattern_id=NEW.source_pattern_id, observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND connec_id=OLD.connec_id;

		ELSIF v_dscenario_type = 'INLET' THEN
			UPDATE inp_dscenario_inlet SET dscenario_id=NEW.dscenario_id, node_id=NEW.node_id, initlevel=NEW.initlevel, minlevel=NEW.minlevel,
			maxlevel=NEW.maxlevel, diameter=NEW.diameter, minvol=NEW.minvol, curve_id=NEW.curve_id, overflow = NEW.overflow, pattern_id = NEW.pattern_id, head = NEW.head,
			mixing_model=NEW.mixing_model, mixing_fraction=NEW.mixing_fraction, reaction_coeff=NEW.reaction_coeff,  init_quality=NEW.init_quality, source_type=NEW.source_type,
			source_quality=NEW.source_quality, source_pattern_id=NEW.source_pattern_id, demand = NEW.demand, demand_pattern_id = NEW.demand_pattern_id, emitter_coeff = NEW.emitter_coeff, 
			observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND node_id=OLD.node_id;

		ELSIF v_dscenario_type = 'VIRTUALPUMP' THEN
			UPDATE inp_dscenario_virtualpump SET dscenario_id=NEW.dscenario_id, node_id=NEW.node_id, power=NEW.power, curve_id=NEW.curve_id,
			speed=NEW.speed, pattern_id=NEW.pattern_id, status=NEW.status,
			effic_curve_id = NEW.effic_curve_id, energy_price = NEW.energy_price, energy_pattern_id = NEW.energy_pattern_id, observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND arc_id=OLD.arc_id;

		ELSIF v_dscenario_type = 'VIRTUALVALVE' THEN
			UPDATE inp_dscenario_virtualvalve SET dscenario_id=NEW.dscenario_id, arc_id=NEW.arc_id, valve_type=NEW.valve_type, setting=NEW.setting,
			curve_id=NEW.curve_id, minorloss=NEW.minorloss, status=NEW.status, init_quality=NEW.init_quality, observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND arc_id=OLD.arc_id;

		ELSIF v_dscenario_type = 'FLWREG-PUMP' THEN
			UPDATE inp_dscenario_frpump SET dscenario_id=NEW.dscenario_id, element_id=NEW.element_id, power=NEW.power, curve_id=NEW.curve_id,
			speed=NEW.speed, pattern_id=NEW.pattern_id, status=NEW.status,
			effic_curve_id = NEW.effic_curve_id, energy_price = NEW.energy_price, energy_pattern_id = NEW.energy_pattern_id, observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND element_id=OLD.element_id;

		ELSIF v_dscenario_type = 'FLWREG-VALVE' THEN
			UPDATE inp_dscenario_frvalve SET dscenario_id=NEW.dscenario_id, element_id=NEW.element_id, valve_type=NEW.valve_type, custom_dint=NEW.custom_dint,
			setting=NEW.setting, curve_id=NEW.curve_id, minorloss=NEW.minorloss, add_settings=NEW.add_settings, init_quality=NEW.init_quality, observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND element_id=OLD.element_id;

		ELSIF v_dscenario_type = 'FLWREG-SHORTPIPE' THEN
			UPDATE inp_dscenario_frshortpipe SET dscenario_id=NEW.dscenario_id, element_id=NEW.element_id, minorloss=NEW.minorloss,
			bulk_coeff=NEW.bulk_coeff, wall_coeff=NEW.wall_coeff, custom_dint=NEW.custom_dint, status=NEW.status, observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND element_id=OLD.element_id;

		ELSIF v_dscenario_type = 'RULES' THEN
			UPDATE inp_dscenario_rules SET dscenario_id = NEW.dscenario_id, sector_id= NEW.sector_id, text= NEW.text, active=NEW.active, observ = NEW.observ
			WHERE id=OLD.id;

		ELSIF v_dscenario_type = 'CONTROLS' THEN
			UPDATE inp_dscenario_controls SET dscenario_id = NEW.dscenario_id, sector_id= NEW.sector_id, text= NEW.text, active=NEW.active, observ = NEW.observ
			WHERE id=OLD.id;

		ELSIF v_dscenario_type = 'MAPZONE' THEN
			UPDATE inp_dscenario_mapzone SET pattern_id = NEW.pattern_id, observ = NEW.observ
			WHERE dscenario_id=OLD.dscenario_id AND mapzone_id=OLD.mapzone_id AND mapzone_type=OLD.mapzone_type;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'DELETE' THEN
		IF v_dscenario_type = 'VALVE' THEN
			DELETE FROM inp_dscenario_valve WHERE dscenario_id=OLD.dscenario_id AND node_id=OLD.node_id;

		ELSIF v_dscenario_type = 'TANK' THEN
			DELETE FROM inp_dscenario_tank WHERE dscenario_id=OLD.dscenario_id AND node_id=OLD.node_id;

		ELSIF v_dscenario_type = 'SHORTPIPE' THEN
			DELETE FROM inp_dscenario_shortpipe WHERE dscenario_id=OLD.dscenario_id AND node_id=OLD.node_id;

		ELSIF v_dscenario_type = 'RESERVOIR' THEN
			DELETE FROM inp_dscenario_reservoir WHERE dscenario_id=OLD.dscenario_id AND node_id=OLD.node_id;

		ELSIF v_dscenario_type = 'PUMP' THEN
			DELETE FROM inp_dscenario_pump WHERE dscenario_id=OLD.dscenario_id AND node_id=OLD.node_id;

		ELSIF v_dscenario_type = 'PIPE' THEN
			DELETE FROM inp_dscenario_pipe WHERE dscenario_id=OLD.dscenario_id AND arc_id=OLD.arc_id;

		ELSIF v_dscenario_type = 'JUNCTION' THEN
			DELETE FROM inp_dscenario_junction WHERE dscenario_id=OLD.dscenario_id AND node_id=OLD.node_id;

		ELSIF v_dscenario_type = 'CONNEC' THEN
			DELETE FROM inp_dscenario_connec WHERE dscenario_id=OLD.dscenario_id AND connec_id=OLD.connec_id;

		ELSIF v_dscenario_type = 'INLET' THEN
			DELETE FROM inp_dscenario_inlet WHERE dscenario_id=OLD.dscenario_id AND node_id=OLD.node_id;

		ELSIF v_dscenario_type = 'VIRTUALVALVE' THEN
			DELETE FROM inp_dscenario_virtualvalve WHERE dscenario_id=OLD.dscenario_id AND arc_id=OLD.arc_id;

		ELSIF v_dscenario_type = 'FLWREG-PUMP' THEN
			DELETE FROM inp_dscenario_frpump WHERE dscenario_id=OLD.dscenario_id AND element_id=OLD.element_id;

		ELSIF v_dscenario_type = 'FLWREG-VALVE' THEN
			DELETE FROM inp_dscenario_frvalve WHERE dscenario_id=OLD.dscenario_id AND element_id=OLD.element_id;

		ELSIF v_dscenario_type = 'FLWREG-SHORTPIPE' THEN
			DELETE FROM inp_dscenario_frshortpipe WHERE dscenario_id=OLD.dscenario_id AND element_id=OLD.element_id;

		ELSIF v_dscenario_type = 'RULES' THEN
			DELETE FROM inp_dscenario_rules WHERE id=OLD.id;

		ELSIF v_dscenario_type = 'CONTROLS' THEN
			DELETE FROM inp_dscenario_controls WHERE id=OLD.id;

		ELSIF v_dscenario_type = 'MAPZONE' THEN
			DELETE FROM inp_dscenario_mapzone WHERE dscenario_id=OLD.dscenario_id AND mapzone_id=OLD.mapzone_id AND mapzone_type=OLD.mapzone_type;

		ELSIF v_dscenario_type = 'PATTERN' THEN
			DELETE FROM inp_dscenario_pattern WHERE dscenario_id=OLD.dscenario_id AND pattern_id=OLD.pattern_id;

		ELSIF v_dscenario_type = 'PATTERN_VALUE' THEN
			DELETE FROM inp_dscenario_pattern_value WHERE dscenario_id=OLD.dscenario_id AND pattern_id=OLD.pattern_id;
		END IF;

		RETURN OLD;
	END IF;
END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

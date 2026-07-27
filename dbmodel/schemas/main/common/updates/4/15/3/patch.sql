/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

ALTER TABLE config_form_fields DISABLE TRIGGER gw_trg_config_control;
UPDATE config_form_fields SET dv_querytext = REPLACE(dv_querytext, 'v_rtc_hydrometer', 'vf_hydrometer') WHERE dv_querytext ILIKE '%v_rtc_hydrometer%';
UPDATE config_form_fields SET dv_querytext = REPLACE(dv_querytext, 'hydrometer_customer_code', 'hydro_customer_code') WHERE dv_querytext ILIKE '%hydrometer_customer_code%';
ALTER TABLE config_form_fields ENABLE TRIGGER gw_trg_config_control;

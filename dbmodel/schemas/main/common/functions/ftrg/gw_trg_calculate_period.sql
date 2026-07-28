/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2648



-- DROP FUNCTION "SCHEMA_NAME".gw_trg_calculate_period();

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_calculate_period()
  RETURNS trigger AS
$BODY$
DECLARE 
	v_record record;
BEGIN

EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||',public';

 IF TG_OP = 'INSERT' THEN -- TO-DO manage TG_OP = 'UPDATE' (recursivity issue)
 
	SELECT * INTO v_record FROM v_cat_period where id = NEW.id;
 
	IF v_record.start_date IS NOT NULL AND v_record.end_date IS NOT NULL AND v_record.end_date >= v_record.start_date THEN
	
	
		UPDATE v_cat_period SET period_seconds = (EXTRACT(EPOCH FROM v_record.end_date::date) - EXTRACT(EPOCH FROM v_record.start_date::date))::integer 
		WHERE v_cat_period.id = NEW.id; 
			
	ELSE
		NEW.period_seconds := (SELECT value FROM config_param_system WHERE  parameter = 'admin_crm_periodseconds_vdefault');

		UPDATE v_cat_period SET period_seconds = NEW.period_seconds WHERE v_cat_period.id = NEW.id; 

	END IF;
END IF;


RETURN NEW;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


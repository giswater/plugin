/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- FUNCTION CODE: 2932

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_ui_rpt_cat_result() RETURNS trigger AS $BODY$
DECLARE
    v_sql varchar;
	v_admin_exploitation_x_user boolean;

BEGIN

    EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
	SELECT value::boolean INTO v_admin_exploitation_x_user FROM config_param_system WHERE parameter = 'admin_exploitation_x_user';

    IF TG_OP = 'INSERT' THEN
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

		-- update descript
		IF NEW.descript IS DISTINCT FROM OLD.descript THEN
			UPDATE rpt_cat_result SET descript = NEW.descript WHERE result_id = NEW.result_id;
		END IF;

		-- update isvalidated
		IF NEW.isvalidated IS DISTINCT FROM OLD.isvalidated THEN
			UPDATE rpt_cat_result SET isvalidated = NEW.isvalidated WHERE result_id = NEW.result_id;
		END IF;

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        v_sql:= 'DELETE FROM rpt_cat_result WHERE result_id = '||quote_literal(OLD.result_id)||';';
		IF v_admin_exploitation_x_user IS FALSE OR v_admin_exploitation_x_user IS NULL THEN
	        EXECUTE v_sql;
		ELSIF v_admin_exploitation_x_user IS TRUE THEN
			IF OLD.cur_user = current_user THEN
				EXECUTE v_sql;
			END IF;
		END IF;
        RETURN NULL;

    END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



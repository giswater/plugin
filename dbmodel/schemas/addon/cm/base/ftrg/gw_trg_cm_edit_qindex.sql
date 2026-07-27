/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/



CREATE OR REPLACE FUNCTION cm.gw_trg_cm_edit_qindex()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$

--FUNCTION CODE: 3560

DECLARE


BEGIN

	-- transaction-local search_path to target schema, parent, public
	PERFORM set_config('search_path', format('%I, PARENT_SCHEMA, public', TG_TABLE_SCHEMA), true);

	IF TG_OP = 'INSERT' THEN -- add new param_names is available

		INSERT INTO config_qindex_suspicious (param_name, threshold, weight, addparam, cur_user)
		VALUES (NEW.param_name, NEW.threshold, NEW.weight, NEW.addparam, current_user)
		ON CONFLICT DO NOTHING;

	ELSIF TG_OP = 'UPDATE' THEN -- existing param_names cannot be modified to avoid misfunction

		UPDATE config_qindex_suspicious 
		SET threshold = NEW.threshold, weight = NEW.weight, addparam = NEW.addparam
		WHERE param_name = NEW.param_name and cur_user = current_user;
	

	END IF;
   
	RETURN NEW;

	EXCEPTION WHEN OTHERS THEN
    RAISE;
END;
$function$
;

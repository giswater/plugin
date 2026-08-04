/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- FUNCTION CODE: 2686


CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_doc() RETURNS trigger AS $BODY$
DECLARE
    doc_table varchar;
    v_sql varchar;
    v_sourcetext json;
    v_targettext text;
    v_record record;
    v_enabled boolean;
	v_repeated_paths text;

BEGIN

    -- set search_path
	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	-- control for spaces or empty on name column
   	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		IF (NEW.name IS NULL OR TRIM(NEW.name) = '') THEN
			NEW.name = NEW.id;
			
			-- future development of variable for some enviroments who they decide to force to put some name for document. Maybe on future create this variable
			--EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"message":"3270", "function":"2686","parameters":null}}$$);';
		END IF;

		-- TODO: See if we can do this check in the future
		-- SELECT string_agg(name, ',') INTO v_repeated_paths FROM doc WHERE path = NEW.path AND id != NEW.id;
		-- IF v_repeated_paths IS NOT NULL THEN
		-- 	EXECUTE format('SELECT gw_fct_getmessage($${"data":{"message":"4540", "function":"2686","parameters":{"repeated_paths":"%s"}}}$$);', v_repeated_paths);
		-- END IF;

	END IF;

   	IF TG_OP = 'INSERT' THEN

	   -- getting config data
	   v_enabled = (SELECT value::json->>'enabled' FROM config_param_system WHERE parameter='edit_replace_doc_folderpath')::boolean;
	   v_sourcetext = (SELECT value::json->>'values' FROM config_param_system WHERE parameter='edit_replace_doc_folderpath')::text;

	   IF v_enabled THEN
			-- looping data
			FOR v_record IN SELECT (a)->>'source' as source,(a)->>'target' as target  FROM json_array_elements(v_sourcetext) a
			LOOP
				NEW.path=REPLACE (NEW.path, v_record.source, v_record.target);
			END LOOP;
	   END IF;

	END IF;

    RETURN NEW;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

  

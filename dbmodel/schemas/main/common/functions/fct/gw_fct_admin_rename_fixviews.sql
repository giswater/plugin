/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE:2636

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_admin_schema_rename_fixviews(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_admin_rename_fixviews(p_data json)
  RETURNS void AS
$BODY$

/*
The goal of this function is fix bug of postgres when schema is renamed because the QUERYS in crosstab function are not automaticly updated

EXAMPLE
SELECT SCHEMA_NAME.gw_fct_admin_rename_fixviews($${ 
"data":{"currentSchemaName":"SCHEMA_NAME","oldSchemaName":"SCHEMA_NAME"}}$$)
*/

DECLARE 

v_viewname text; 
v_oldschemaname text;
v_newschemaname text;
v_definition text;
	
BEGIN 

	-- Search path
    SET search_path = "SCHEMA_NAME", public;
	
	-- get input data
	v_oldschemaname := ((p_data->>'data')::json)->>'oldSchemaName'::text;
	v_newschemaname := ((p_data->>'data')::json)->>'currentSchemaName'::text; 

	-- views 
	FOR v_viewname IN SELECT viewname from pg_views where schemaname = v_newschemaname
	LOOP
		SELECT pg_get_viewdef(v_newschemaname||'.'||v_viewname, true) INTO v_definition;
		
		-- replace definition (because CROSSTAB are not automaticly updated)
		SELECT replace(v_definition, 'FROM '||v_oldschemaname||'.', 'FROM '||v_newschemaname||'.') INTO v_definition;
		SELECT replace(v_definition, 'JOIN '||v_oldschemaname||'.', 'JOIN '||v_newschemaname||'.') INTO v_definition;
		
		-- execute new definition
		BEGIN
			EXECUTE 'CREATE OR REPLACE VIEW '||v_newschemaname||'.'||v_viewname||' AS '||v_definition;
		EXCEPTION WHEN insufficient_privilege THEN
			RAISE NOTICE 'View %.% not replaced: %', v_newschemaname, v_viewname, SQLERRM;
		END;

	END LOOP;
	
	RETURN;
		
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

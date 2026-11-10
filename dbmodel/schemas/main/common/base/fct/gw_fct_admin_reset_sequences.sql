/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE:3152

-- DROP FUNCTION SCHEMA_NAME.gw_fct_admin_reset_sequences();

CREATE or replace FUNCTION SCHEMA_NAME.gw_fct_admin_reset_sequences()
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE 
v_project_type text;
v_version text;
v_result json;
v_error_context text;
v_max integer;

rec record;
v_sequence text;
BEGIN

    EXECUTE 'SET search_path = SCHEMA_NAME, public';
    
    -- select config values
    SELECT project_type, giswater INTO v_project_type, v_version FROM sys_version order by id desc limit 1;

    FOR rec IN (SELECT DISTINCT table_name ,column_name FROM INFORMATION_SCHEMA.key_column_usage
        WHERE table_name IN (SELECT id FROM sys_table) AND TABLE_SCHEMA IN ('SCHEMA_NAME') AND (table_name ilike 'anl%' OR table_name ilike 'audit%' OR table_name ilike 'temp_%') and table_name not ilike 'temp_link%'
        and constraint_name  ilike '%pkey' order by 1) LOOP 

        select pg_get_serial_sequence(rec.table_name, rec.column_name) INTO v_sequence;

            IF v_sequence IS NOT NULL THEN

            EXECUTE 'UPDATE '||rec.table_name||' a SET '||rec.column_name||'='||rec.column_name||'+100000000';
            
            EXECUTE 'UPDATE '||rec.table_name||' a SET '||rec.column_name||'=row_id FROM (SELECT row_number() OVER() AS row_id, '||rec.column_name||' 
            FROM '||rec.table_name||')b 
            WHERE b.'||rec.column_name||'=a.'||rec.column_name||'';


            EXECUTE 'SELECT max('||rec.column_name||'::integer) FROM '||rec.table_name||''
            INTO v_max;

            EXECUTE 'SELECT max('||rec.column_name||'::integer) FROM '||rec.table_name||''
            INTO v_max;

            IF v_max IS NULL THEN
                v_max=1;
            END IF;
            EXECUTE 'SELECT setval('||quote_literal(v_sequence)||',('||v_max||'), true);';
        END IF;

    END LOOP;

    v_result := COALESCE(v_result, '{}'); 

    -- Return
    RETURN gw_fct_json_create_return(('{"status":"Accepted", "message":{"level":1, "text":"Sequence reset done succesfully"}, "version":"'||v_version||'"'||
             ',"body":{"form":{}'||
             ',"data":{ "info":'||v_result||'}'||
               '}'||
        '}')::json, 3152, null, null, null);

END;
$BODY$;

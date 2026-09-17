/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3568

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_resolve_list_query(text, integer);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_resolve_list_query(
    p_tablename text,
    p_device integer
)
RETURNS json AS
$BODY$

DECLARE
    v_schemaname text := 'SCHEMA_NAME';
    v_query_text text;
    v_default json;
    v_listtype text;
    v_idname text;
    v_the_geom text;

BEGIN
    SET search_path = "SCHEMA_NAME", public;

    IF p_tablename IN (SELECT table_name FROM information_schema.tables WHERE table_schema = v_schemaname) THEN

        EXECUTE 'SELECT a.attname FROM pg_index i JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey) WHERE  i.indrelid = $1::regclass AND i.indisprimary'
            INTO v_idname
            USING p_tablename;

        IF v_idname ISNULL THEN
            EXECUTE 'SELECT a.attname FROM pg_attribute a   JOIN pg_class t on a.attrelid = t.oid  JOIN pg_namespace s on t.relnamespace = s.oid WHERE a.attnum > 0   AND NOT a.attisdropped
                AND t.relname = $1
                AND s.nspname = $2
                ORDER BY a.attnum LIMIT 1'
                    INTO v_idname
                    USING p_tablename, v_schemaname;
        END IF;

        EXECUTE 'SELECT attname FROM pg_attribute a
        JOIN pg_class t on a.attrelid = t.oid
        JOIN pg_namespace s on t.relnamespace = s.oid
        WHERE a.attnum > 0
        AND NOT a.attisdropped
        AND t.relname = $1
        AND s.nspname = $2
        AND left (pg_catalog.format_type(a.atttypid, a.atttypmod), 8)=''geometry''
        ORDER BY a.attnum'
            USING p_tablename, v_schemaname
            INTO v_the_geom;

        EXECUTE 'SELECT query_text, vdefault, listtype FROM config_form_list WHERE listname = $1 AND device = $2'
            INTO v_query_text, v_default, v_listtype
            USING p_tablename, p_device;

        IF v_query_text IS NULL THEN
            EXECUTE 'SELECT query_text, vdefault, listtype FROM config_form_list WHERE listname = $1 LIMIT 1'
                INTO v_query_text, v_default, v_listtype
                USING p_tablename;
        END IF;

        IF v_query_text IS NULL THEN
            v_query_text = 'SELECT * FROM '||p_tablename||' WHERE '||v_idname||' IS NOT NULL ';
        END IF;

    ELSE
        EXECUTE 'SELECT query_text, vdefault, listtype FROM config_form_list WHERE listname = $1 AND device = $2'
            INTO v_query_text, v_default, v_listtype
            USING p_tablename, p_device;

        IF v_query_text IS NULL THEN
            EXECUTE 'SELECT query_text, vdefault, listtype FROM config_form_list WHERE listname = $1 LIMIT 1'
                INTO v_query_text, v_default, v_listtype
                USING p_tablename;
        END IF;
    END IF;

    RETURN json_build_object(
        'queryText', v_query_text,
        'listtype', v_listtype,
        'vdefault', COALESCE(v_default, '{}'::json),
        'theGeomCol', v_the_geom
    );

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3566

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_get_multilang_language();
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_get_multilang_language(text);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_get_multilang_language(p_schema_name text)
RETURNS jsonb AS
$BODY$
/*
Returns jsonb {"lang": "...", "project_type": "..."} from the network schema
config_param_user preference (multilang_language) and sys_version.project_type,
or NULL when unset / invalid / default.
*/
DECLARE
    v_lang text;
    v_project_type text;
    v_schema text;
BEGIN
    v_schema := NULLIF(btrim(p_schema_name), '');
    IF v_schema IS NULL
       OR to_regnamespace(v_schema) IS NULL
       OR to_regclass('multilang.cat_language') IS NULL THEN
        RETURN NULL;
    END IF;

    BEGIN
        EXECUTE format(
            'SELECT lower(btrim(cpu.value)), lower(btrim(sv.project_type))
             FROM %1$I.sys_version sv
             LEFT JOIN %1$I.config_param_user cpu
               ON cpu.parameter = ''multilang_language''
              AND cpu.cur_user = current_user
             WHERE lower(btrim(cpu.value)) IS NOT NULL
               AND lower(btrim(cpu.value)) <> ''default''
               AND length(lower(btrim(cpu.value))) = 5
               AND EXISTS (
                   SELECT 1 FROM multilang.cat_language cl
                   WHERE cl.id = lower(btrim(cpu.value))
               )
             ORDER BY sv.id DESC
             LIMIT 1',
            v_schema
        ) INTO STRICT v_lang, v_project_type;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    IF v_project_type IS NULL OR btrim(v_project_type) = '' THEN
        RETURN NULL;
    END IF;

    RETURN jsonb_build_object(
        'lang', v_lang,
        'project_type', v_project_type
    );
END;
$BODY$
  LANGUAGE plpgsql STABLE
  COST 100;

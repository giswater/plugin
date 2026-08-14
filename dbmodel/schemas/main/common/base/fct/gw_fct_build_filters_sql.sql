/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3566

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_build_filters_sql(json, text);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_build_filters_sql(
    p_filter_fields json,
    p_listtype text DEFAULT NULL
)
RETURNS text AS
$BODY$

DECLARE
    v_fields varchar[];
    v_field varchar;
    v_length integer;
    v_value text;
    v_text text[];
    v_json_field json;
    text text;
    j integer;
    v_sign text;
    v_type text;
    v_logical text;
    v_filter_sql text := '';
    v_idx integer := 1;

BEGIN
    SELECT array_agg(row_to_json(a)) INTO v_text FROM json_each(p_filter_fields) a;

    IF v_text IS NULL THEN
        RETURN '';
    END IF;

    FOREACH text IN ARRAY v_text
    LOOP
        SELECT v_text[v_idx] INTO v_json_field;

        v_fields := string_to_array((SELECT (v_json_field ->> 'key')), ', ');
        v_value := (SELECT (v_json_field ->> 'value'));
        v_length := array_length(v_fields, 1);
        v_sign := NULL;

        IF (v_length = 1) THEN
            v_field := v_fields[1];
        END IF;

        IF (SELECT v_value WHERE v_value ILIKE '%'||'filterType'||'%') IS NOT NULL THEN
            v_type = v_value::json->>'filterType';
        ELSE
            v_type = 'text';
        END IF;

        IF (SELECT v_value WHERE v_value ILIKE '%'||'filterSign'||'%') IS NOT NULL THEN
            v_sign = upper(v_value::json->>'filterSign');
            v_value = v_value::json->>'value';
            IF upper(v_sign) IN ('LIKE', 'ILIKE') THEN
                v_value = '%'||v_value||'%';
            END IF;
        ELSE
            IF p_listtype = 'attributeTable' THEN
                v_sign = 'ILIKE';
            ELSIF v_sign IS NULL THEN
                v_sign = '=';
            END IF;
        END IF;

        IF v_length = 1 AND v_value IS NOT NULL AND v_field != 'limit' THEN
            IF v_sign = 'IN' THEN
                IF left(trim(v_value), 1) = '[' THEN
                    SELECT string_agg(quote_literal(elem), ', ')
                    INTO v_value
                    FROM jsonb_array_elements_text(v_value::jsonb) elem;
                ELSE
                    v_value := quote_literal(v_value);
                END IF;
                v_filter_sql := v_filter_sql || ' AND "'||v_field||'"::'||v_type||' IN ('||v_value||') ';
            ELSIF upper(v_type) = 'BETWEEN' THEN
                v_filter_sql := v_filter_sql || ' AND "'||v_field||'"::'||v_type||' '||v_sign||' '||v_value||'::'||v_type||' ';
            ELSE
                v_filter_sql := v_filter_sql || ' AND "'||v_field||'"::'||v_type||' '||v_sign||' '''||v_value||'''::'||v_type||' ';
            END IF;
        ELSIF v_length > 1 AND v_value IS NOT NULL THEN
            v_filter_sql := v_filter_sql || ' AND (';
            FOR j IN array_lower(v_fields, 1)..array_upper(v_fields, 1) LOOP
                v_logical := 'OR';
                IF j = 1 THEN
                    v_logical := '';
                END IF;
                v_filter_sql := v_filter_sql || ' '||v_logical||' "'||v_fields[j]||'"::'||v_type||' '||v_sign||' '''||v_value||'''::'||v_type||' ';
            END LOOP;
            v_filter_sql := v_filter_sql || ')';
        END IF;

        v_idx := v_idx + 1;
    END LOOP;

    RETURN v_filter_sql;

END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

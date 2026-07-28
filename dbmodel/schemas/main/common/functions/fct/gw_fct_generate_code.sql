/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- FUNCTION CODE: 3542

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_get_mapzone_code(text, json);

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_generate_code(text, text, text);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_generate_code(text, text, text, json);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_generate_code(text, text, integer);
DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_generate_code(text, text, integer, json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_generate_code(
    p_context text,
    p_class text,
    p_data json DEFAULT NULL
)
RETURNS text AS
$BODY$

/* NOTE Example usage:

SELECT gw_fct_generate_code('feature', 'MANHOLE', '{"node_id": 1, "node_type": "MANHOLE"}'::json);
SELECT gw_fct_generate_code('mapzone', 'DMA', '{"dma_id": 1, "the_geom": ...}'::json);

-- Code is built from config_code_parts: active rows ordered by concat_order.
-- entity NULL = global within context; entity-specific row overrides global at the same concat_order.
-- Bind params: $1 = row json from trigger, $2 = p_class (mapzone id or catalog id).

*/

DECLARE
    v_entity text;
    v_query text;
    v_code text;
    v_parts text;

BEGIN

    SET search_path = "SCHEMA_NAME", public;

    IF p_context = 'feature' THEN

        SELECT cf.feature_type
        INTO v_entity
        FROM cat_feature cf
        WHERE cf.id = p_class
          AND cf.code_autofill IS TRUE;

    ELSIF p_context = 'mapzone' THEN

        SELECT cm.id
        INTO v_entity
        FROM config_mapzones cm
        WHERE cm.id = p_class
          AND cm.code_autofill IS TRUE;

    ELSE
        RETURN NULL;
    END IF;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    SELECT string_agg('(' || source_expr || ')', ', ' ORDER BY concat_order)
    INTO v_parts
    FROM (
        SELECT t.source_expr, t.concat_order
        FROM config_code_parts t
        WHERE t.context = p_context
          AND t.active IS TRUE
          AND (t.entity = v_entity OR t.entity IS NULL)
          AND NOT (
              t.entity IS NULL
              AND EXISTS (
                  SELECT 1
                  FROM config_code_parts t2
                  WHERE t2.context = t.context
                    AND t2.concat_order = t.concat_order
                    AND t2.entity = v_entity
                    AND t2.active IS TRUE
              )
          )
    ) q;

    IF v_parts IS NULL OR btrim(v_parts) = '' THEN
        RETURN NULL;
    END IF;

    v_query := 'SELECT concat(' || v_parts || ')';

    BEGIN
        EXECUTE v_query INTO v_code USING p_data, p_class;
    EXCEPTION WHEN OTHERS THEN
        RETURN NULL;
    END;

    RETURN v_code;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

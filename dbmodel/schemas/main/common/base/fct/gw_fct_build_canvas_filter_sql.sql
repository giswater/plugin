/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3570

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_build_canvas_filter_sql(text, double precision, double precision, double precision, double precision, integer);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_build_canvas_filter_sql(
    p_geom_expr text,
    p_x1 double precision,
    p_y1 double precision,
    p_x2 double precision,
    p_y2 double precision,
    p_srid integer
)
RETURNS text AS
$BODY$

BEGIN
    IF p_geom_expr IS NULL OR p_x1 IS NULL OR p_y1 IS NULL OR p_x2 IS NULL OR p_y2 IS NULL OR p_srid IS NULL THEN
        RETURN '';
    END IF;

    RETURN ' AND ST_dwithin('||p_geom_expr||', ST_MakePolygon(ST_GeomFromText(''LINESTRING ('||p_x1||' '||p_y1||', '||
        p_x1||' '||p_y2||', '||p_x2||' '||p_y2||', '||p_x2||' '||p_y1||', '||p_x1||' '||p_y1||')'','||p_srid||')),1)';
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

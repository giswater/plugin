/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- 4.7.0 recast dma.the_geom to a hardcoded 25831. New projects pick this up via
-- version_walk; this bump retags existing UD schemas to sys_version / SRID_VALUE.
DROP VIEW IF EXISTS ve_dma;
ALTER TABLE dma ALTER COLUMN the_geom TYPE public.geometry(multipolygon, SRID_VALUE)
    USING ST_SetSRID(the_geom, SRID_VALUE);

CREATE OR REPLACE VIEW ve_dma
AS
SELECT d.dma_id,
    d.code,
    d.name,
    d.descript,
    d.active,
    d.dma_type,
    d.expl_id,
    d.sector_id,
    d.muni_id,
    d.avg_press,
    d.pattern_id,
    d.effc,
    d.graphconfig::text AS graphconfig,
    d.stylesheet,
    d.lock_level,
    d.link,
    d.the_geom,
    d.addparam::text AS addparam,
    d.created_at,
    d.created_by,
    d.updated_at,
    d.updated_by
FROM dma d
WHERE d.dma_id > 0
  AND (
      d.expl_id IS NULL
      OR d.expl_id = '{}'::int4[]
      OR 0 = ANY (d.expl_id)
      OR EXISTS (
          SELECT 1
          FROM vf_exploitation ve
          WHERE ve.expl_id = ANY (d.expl_id)
      )
  );

CREATE TRIGGER gw_trg_v_edit_dma INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_dma
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_dma('EDIT');

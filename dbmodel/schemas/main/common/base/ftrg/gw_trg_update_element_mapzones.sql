/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3540


CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_update_element_mapzones()
RETURNS trigger AS
$BODY$
DECLARE
	v_project_type text;
	v_total integer;
	v_muni_id integer;
	v_expl_id integer;
	v_sector_id integer;
	v_the_geom public.geometry;
	v_table text;
	v_query text;

BEGIN

	SELECT project_type INTO v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

	IF TG_OP = 'INSERT' THEN

		v_query = 'SELECT count(*) FROM (
			SELECT element_id FROM element_x_node WHERE element_id = '|| NEW.element_id ||'
			UNION ALL
			SELECT element_id FROM element_x_arc WHERE element_id = '|| NEW.element_id ||'
			UNION ALL
			SELECT element_id FROM element_x_connec WHERE element_id = '|| NEW.element_id ||'
			UNION ALL
			SELECT element_id FROM element_x_link WHERE element_id = '|| NEW.element_id;

		IF v_project_type = 'UD' THEN
			v_query = v_query || ' UNION ALL
			SELECT element_id FROM element_x_gully WHERE element_id = '|| NEW.element_id;
		END IF;

		v_query = v_query || ') a';

		EXECUTE v_query INTO v_total;

		-- We only update the mapzones columns on the insert, and if the element has one feature associated with it
		IF v_total = 1 THEN

			v_table = TG_ARGV[0];

			IF v_table = 'element_x_node' THEN
				SELECT muni_id, expl_id, sector_id, the_geom INTO v_muni_id, v_expl_id, v_sector_id, v_the_geom
				FROM node WHERE node_id = NEW.node_id;

			ELSIF v_table = 'element_x_arc' THEN
				SELECT muni_id, expl_id, sector_id, the_geom INTO v_muni_id, v_expl_id, v_sector_id, v_the_geom
				FROM arc WHERE arc_id = NEW.arc_id;

			ELSIF v_table = 'element_x_connec' THEN
				SELECT muni_id, expl_id, sector_id, the_geom INTO v_muni_id, v_expl_id, v_sector_id, v_the_geom
				FROM connec WHERE connec_id = NEW.connec_id;

			ELSIF v_table = 'element_x_link' THEN
				SELECT muni_id, expl_id, sector_id, the_geom INTO v_muni_id, v_expl_id, v_sector_id, v_the_geom
				FROM link WHERE link_id = NEW.link_id;

			ELSIF v_table = 'element_x_gully' THEN
				SELECT muni_id, expl_id, sector_id, the_geom INTO v_muni_id, v_expl_id, v_sector_id, v_the_geom
				FROM gully WHERE gully_id = NEW.gully_id;
			END IF;

			UPDATE element SET muni_id = v_muni_id, expl_id = v_expl_id, sector_id = v_sector_id
			WHERE element_id = NEW.element_id;

			-- First link only (v_total = 1). Copy a point when the element has none.
			-- Arcs and links contribute their midpoint. FRELEM keeps a null geometry.
			IF (SELECT value::boolean FROM config_param_system WHERE parameter = 'edit_element_geom_from_feature') IS TRUE
			AND v_the_geom IS NOT NULL
			AND (SELECT the_geom FROM element WHERE element_id = NEW.element_id) IS NULL
			AND NOT EXISTS (
				SELECT 1
				FROM element e
				JOIN cat_element ce ON ce.id = e.elementcat_id
				JOIN cat_feature cf ON cf.id = ce.element_type
				WHERE e.element_id = NEW.element_id
				AND upper(cf.feature_class) = 'FRELEM'
			) THEN
				UPDATE element
				SET the_geom = CASE
					WHEN ST_GeometryType(v_the_geom) IN ('ST_LineString', 'ST_MultiLineString') THEN
						ST_LineInterpolatePoint(ST_LineMerge(v_the_geom), 0.5)
					ELSE v_the_geom
				END
				WHERE element_id = NEW.element_id
				AND the_geom IS NULL;
			END IF;

		END IF;

	END IF;

	RETURN NULL;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

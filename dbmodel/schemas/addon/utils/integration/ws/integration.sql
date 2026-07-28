/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = "SCHEMA_NAME", public, pg_catalog;

ALTER TABLE IF EXISTS ext_address RENAME TO ext_address_old;
ALTER TABLE IF EXISTS ext_cat_raster RENAME TO ext_cat_raster_old;
ALTER TABLE IF EXISTS ext_district RENAME TO ext_district_old;
ALTER TABLE IF EXISTS ext_region_x_province RENAME TO ext_region_x_province_old;
ALTER TABLE IF EXISTS ext_municipality RENAME TO ext_municipality_old;
ALTER TABLE IF EXISTS ext_plot RENAME TO ext_plot_old;
ALTER TABLE IF EXISTS ext_province RENAME TO ext_province_old;
ALTER TABLE IF EXISTS ext_raster_dem RENAME TO ext_raster_dem_old;
ALTER TABLE IF EXISTS ext_region RENAME TO ext_region_old;
ALTER TABLE IF EXISTS ext_streetaxis RENAME TO ext_streetaxis_old;
ALTER TABLE IF EXISTS ext_type_street RENAME TO ext_type_street_old;

CREATE OR REPLACE VIEW v_municipality AS
SELECT * FROM utils.municipality;

CREATE OR REPLACE VIEW v_streetaxis AS
SELECT * FROM utils.streetaxis;

CREATE OR REPLACE VIEW v_address AS
SELECT * FROM utils.address;

CREATE OR REPLACE VIEW v_plot AS
SELECT * FROM utils.plot;

CREATE OR REPLACE VIEW v_raster_dem AS
SELECT * FROM utils.raster_dem;

CREATE OR REPLACE VIEW v_ext_raster_dem
AS SELECT DISTINCT ON (r.id) r.id,
    c.code,
    c.alias,
    c.raster_type,
    c.descript,
    c.source,
    c.provider,
    c.year,
    r.rast,
    r.rastercat_id,
    r.envelope
   FROM ve_municipality a,
    v_raster_dem r
     JOIN utils.cat_raster c ON c.id = r.rastercat_id
  WHERE st_dwithin(r.envelope, a.the_geom, 0::double precision);

CREATE OR REPLACE VIEW v_district AS
SELECT * FROM utils.district;

CREATE OR REPLACE VIEW v_region AS
SELECT * FROM utils.region;

CREATE OR REPLACE VIEW v_province AS
SELECT * FROM utils.province;

CREATE OR REPLACE VIEW v_type_street AS
SELECT * FROM utils.type_street;

SELECT "SCHEMA_NAME".gw_fct_admin_sys_version_register(json_build_object(
	'data', json_build_object(
		'gwVersion', (SELECT giswater FROM sys_version ORDER BY id DESC LIMIT 1),
		'mergeAddparam', json_build_object(
			'satellites', json_build_object(
				'utils', json_build_object('enabled', true, 'schema', 'utils')
			)
		)
	)
)::json);

DELETE FROM sys_table WHERE id = 'ext_address';
DELETE FROM sys_table WHERE id = 'ext_municipality';
DELETE FROM sys_table WHERE id = 'ext_streetaxis';
DELETE FROM sys_table WHERE id = 'ext_plot';
DELETE FROM sys_table WHERE id = 'ext_cat_raster';
DELETE FROM sys_table WHERE id = 'ext_raster_dem';
DELETE FROM sys_table WHERE id = 'ext_district';
DELETE FROM sys_table WHERE id = 'ext_region';
DELETE FROM sys_table WHERE id = 'ext_region_x_province';
DELETE FROM sys_table WHERE id = 'ext_province';
DELETE FROM sys_table WHERE id = 'ext_type_street';

DO $gw$
BEGIN
	-- Copy ext_* → utils in FK dependency order (province/region → municipality → streetaxis → plot → address).
	IF to_regclass('ext_province_old') IS NOT NULL THEN
		INSERT INTO utils.province (province_id, name, descript, the_geom, active, code)
		SELECT province_id, name, descript, the_geom, active, code
		FROM ext_province_old ON CONFLICT (province_id) DO NOTHING;
	END IF;
	IF to_regclass('ext_region_old') IS NOT NULL THEN
		INSERT INTO utils.region (region_id, name, descript, the_geom, active, code)
		SELECT region_id, name, descript, the_geom, active, code
		FROM ext_region_old ON CONFLICT (region_id) DO NOTHING;
	END IF;
	IF to_regclass('ext_region_x_province_old') IS NOT NULL THEN
		INSERT INTO utils.region_x_province (region_id, province_id)
		SELECT region_id, province_id
		FROM ext_region_x_province_old ON CONFLICT (region_id, province_id) DO NOTHING;
	END IF;
	IF to_regclass('ext_municipality_old') IS NOT NULL THEN
		INSERT INTO utils.municipality (muni_id, name, observ, the_geom, active, region_id, province_id, code)
		SELECT muni_id, name, observ, the_geom, active, region_id, province_id, code
		FROM ext_municipality_old ON CONFLICT (muni_id) DO NOTHING;
	END IF;
	IF to_regclass('ext_district_old') IS NOT NULL THEN
		INSERT INTO utils.district (district_id, name, muni_id, observ, active, the_geom, code)
		SELECT district_id, name, muni_id, observ, active, the_geom, code
		FROM ext_district_old ON CONFLICT (district_id) DO NOTHING;
	END IF;
	IF to_regclass('ext_type_street_old') IS NOT NULL THEN
		INSERT INTO utils.type_street (id, observ)
		SELECT id, observ FROM ext_type_street_old ON CONFLICT (id) DO NOTHING;
	END IF;
	IF to_regclass('ext_streetaxis_old') IS NOT NULL THEN
		INSERT INTO utils.streetaxis (id, code, type, name, text, the_geom, muni_id, source)
		SELECT id, code, type, name, text, the_geom, muni_id, source
		FROM ext_streetaxis_old ON CONFLICT (id) DO NOTHING;
	END IF;
	IF to_regclass('ext_plot_old') IS NOT NULL THEN
		INSERT INTO utils.plot (id, code, muni_id, postcode, streetaxis_id, postnumber, complement, placement, square, observ, text, the_geom)
		SELECT id, code, muni_id, postcode, streetaxis_id, postnumber, complement, placement, square, observ, text, the_geom
		FROM ext_plot_old ON CONFLICT (id) DO NOTHING;
	END IF;
	IF to_regclass('ext_address_old') IS NOT NULL THEN
		INSERT INTO utils.address (id, muni_id, postcode, streetaxis_id, postnumber, plot_id, the_geom, postcomplement, code, source)
		SELECT id, muni_id, postcode, streetaxis_id, postnumber, plot_id, the_geom, postcomplement, code, source
		FROM ext_address_old ON CONFLICT (id) DO NOTHING;
	END IF;
	IF to_regclass('ext_cat_raster_old') IS NOT NULL THEN
		INSERT INTO utils.cat_raster SELECT * FROM ext_cat_raster_old ON CONFLICT DO NOTHING;
	END IF;
	IF to_regclass('ext_raster_dem_old') IS NOT NULL THEN
		INSERT INTO utils.raster_dem SELECT * FROM ext_raster_dem_old ON CONFLICT DO NOTHING;
	END IF;
END
$gw$;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

ALTER TABLE node DROP CONSTRAINT node_district_id_fkey;
ALTER TABLE node ADD CONSTRAINT node_district_id_fkey FOREIGN KEY (district_id) REFERENCES utils.district(district_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE arc DROP CONSTRAINT arc_district_id_fkey;
ALTER TABLE arc ADD CONSTRAINT arc_district_id_fkey FOREIGN KEY (district_id) REFERENCES utils.district(district_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE connec DROP CONSTRAINT connec_district_id_fkey;
ALTER TABLE connec ADD CONSTRAINT connec_district_id_fkey FOREIGN KEY (district_id) REFERENCES utils.district(district_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE connec DROP CONSTRAINT connec_plot_id_fkey;
ALTER TABLE connec ADD CONSTRAINT connec_plot_id_fkey FOREIGN KEY (plot_id) REFERENCES utils.plot(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE link DROP CONSTRAINT link_muni_id_fkey;
ALTER TABLE link ADD CONSTRAINT link_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES utils.municipality(muni_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE element DROP CONSTRAINT element_muni_id_fkey;
ALTER TABLE element ADD CONSTRAINT element_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES utils.municipality(muni_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE selector_municipality DROP CONSTRAINT selector_municipality_fkey;
ALTER TABLE selector_municipality ADD CONSTRAINT selector_municipality_fkey FOREIGN KEY (muni_id) REFERENCES utils.municipality(muni_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE om_visit DROP CONSTRAINT om_visit_muni_id_fkey;
ALTER TABLE om_visit ADD CONSTRAINT om_visit_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES utils.municipality(muni_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE dimensions DROP CONSTRAINT dimensions_muni_id;
ALTER TABLE dimensions DROP CONSTRAINT dimensions_muni_id_fkey;
ALTER TABLE dimensions ADD CONSTRAINT dimensions_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES utils.municipality(muni_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE om_mincut DROP CONSTRAINT om_mincut_muni_id;
ALTER TABLE om_mincut ADD CONSTRAINT om_mincut_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES utils.municipality(muni_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE node DROP CONSTRAINT node_muni_id_fkey;
ALTER TABLE node ADD CONSTRAINT node_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES utils.municipality(muni_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE arc DROP CONSTRAINT arc_muni_id_fkey;
ALTER TABLE arc ADD CONSTRAINT arc_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES utils.municipality(muni_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE connec DROP CONSTRAINT connec_muni_id_fkey;
ALTER TABLE connec ADD CONSTRAINT connec_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES utils.municipality(muni_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE om_streetaxis DROP CONSTRAINT om_streetaxis_muni_id_fkey;
ALTER TABLE om_streetaxis ADD CONSTRAINT om_streetaxis_muni_id_fkey FOREIGN KEY (muni_id) REFERENCES utils.municipality(muni_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE node DROP CONSTRAINT node_streetaxis_id_fkey;
ALTER TABLE node ADD CONSTRAINT node_streetaxis_id_fkey FOREIGN KEY (muni_id, streetaxis_id) REFERENCES utils.streetaxis(muni_id, id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE node DROP CONSTRAINT node_streetaxis2_id_fkey;
ALTER TABLE node ADD CONSTRAINT node_streetaxis2_id_fkey FOREIGN KEY (muni_id, streetaxis_id) REFERENCES utils.streetaxis(muni_id, id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE arc DROP CONSTRAINT arc_streetaxis_id_fkey;
ALTER TABLE arc ADD CONSTRAINT arc_streetaxis_id_fkey FOREIGN KEY (muni_id, streetaxis_id) REFERENCES utils.streetaxis(muni_id, id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE arc DROP CONSTRAINT arc_streetaxis2_id_fkey;
ALTER TABLE arc ADD CONSTRAINT arc_streetaxis2_id_fkey FOREIGN KEY (muni_id, streetaxis_id) REFERENCES utils.streetaxis(muni_id, id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE connec DROP CONSTRAINT connec_streetaxis_id_fkey;
ALTER TABLE connec ADD CONSTRAINT connec_streetaxis_id_fkey FOREIGN KEY (muni_id, streetaxis_id) REFERENCES utils.streetaxis(muni_id, id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE connec DROP CONSTRAINT connec_streetaxis2_id_fkey;
ALTER TABLE connec ADD CONSTRAINT connec_streetaxis2_id_fkey FOREIGN KEY (muni_id, streetaxis_id) REFERENCES utils.streetaxis(muni_id, id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE IF EXISTS ext_raster_dem_old DROP CONSTRAINT IF EXISTS raster_dem_rastercat_id_fkey;
ALTER TABLE IF EXISTS ext_streetaxis_old DROP CONSTRAINT IF EXISTS ext_streetaxis_muni_id_fkey;
ALTER TABLE IF EXISTS ext_streetaxis_old DROP CONSTRAINT IF EXISTS ext_streetaxis_type_street_fkey;
ALTER TABLE IF EXISTS ext_address_old DROP CONSTRAINT IF EXISTS ext_address_muni_id_fkey;
ALTER TABLE IF EXISTS ext_address_old DROP CONSTRAINT IF EXISTS ext_address_plot_id_fkey;
ALTER TABLE IF EXISTS ext_address_old DROP CONSTRAINT IF EXISTS ext_address_streetaxis_id_fkey;
ALTER TABLE IF EXISTS ext_plot_old DROP CONSTRAINT IF EXISTS ext_plot_muni_id_fkey;
ALTER TABLE IF EXISTS ext_plot_old DROP CONSTRAINT IF EXISTS ext_plot_streetaxis_id_fkey;
ALTER TABLE IF EXISTS ext_district_old DROP CONSTRAINT IF EXISTS ext_district_muni_id_fkey;
ALTER TABLE IF EXISTS ext_municipality_old DROP CONSTRAINT IF EXISTS ext_municipality_province_id_fkey;
ALTER TABLE IF EXISTS ext_municipality_old DROP CONSTRAINT IF EXISTS ext_municipality_region_id_fkey;


DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON sector;
DROP TRIGGER IF EXISTS gw_trg_fk_array_id_table ON sector;
DROP TRIGGER IF EXISTS gw_trg_fk_array_id_table_update ON sector;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON presszone;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON dma;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON macrodma;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON macrosector;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON dqa;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON macrodqa;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON omzone;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON macroomzone;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON supplyzone;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON crmzone;

CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT
OR UPDATE OF muni_id ON
sector FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');
CREATE TRIGGER gw_trg_fk_array_id_table BEFORE DELETE ON
sector FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('sector_id', '{"utils.municipality":"sector_id", "exploitation":"sector_id"}');
CREATE TRIGGER gw_trg_fk_array_id_table_update AFTER UPDATE OF sector_id ON
sector FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_id_table('sector_id', '{"utils.municipality":"sector_id", "exploitation":"sector_id"}');

CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT
OR UPDATE OF muni_id ON
presszone FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');

CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT
OR UPDATE OF muni_id ON
dma FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');

CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT
OR UPDATE OF muni_id ON
macrodma FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');

CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT
OR UPDATE OF muni_id ON
macrosector FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');

CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT
OR UPDATE OF muni_id ON
dqa FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');

CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT
OR UPDATE OF muni_id ON
macrodqa FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');

CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT
OR UPDATE OF muni_id ON
omzone FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');

CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT
OR UPDATE OF muni_id ON
macroomzone FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');

CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT
OR UPDATE OF muni_id ON
supplyzone FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');

CREATE TRIGGER gw_trg_fk_array_array_table_muni AFTER INSERT
OR UPDATE OF muni_id ON
crmzone FOR EACH ROW EXECUTE FUNCTION gw_trg_array_fk_array_table('muni_id', 'utils.municipality', 'muni_id');

SELECT utils.gw_fct_admin_sys_version_register(json_build_object(
	'data', json_build_object(
		'parentSchema', 'SCHEMA_NAME',
		'parentKind', 'ws'
	)
)::json);

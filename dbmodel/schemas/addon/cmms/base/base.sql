/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = cmms, public;

CREATE TABLE sys_version (
	id serial4 NOT NULL,
	giswater varchar(16) NOT NULL,
	project_type varchar(16) NOT NULL,
	postgres varchar(512) NOT NULL,
	postgis varchar(512) NOT NULL,
	"date" timestamp(6) DEFAULT now() NOT NULL,
	"language" varchar(50) NOT NULL,
	epsg int4 NOT NULL,
	addparam jsonb,
	CONSTRAINT sys_version_pkey PRIMARY KEY (id)
);

-- =================================================================================
-- TAULA visit (id UUID global)
-- =================================================================================
CREATE TABLE IF NOT EXISTS cmms.visit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ext_visit_id TEXT,
  type VARCHAR(50) NOT NULL,
  status VARCHAR(50) NOT NULL,
  title VARCHAR(255),
  description TEXT,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  the_geom geometry(MultiPolygon, SRID_VALUE),
  properties jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by VARCHAR(255),
  CONSTRAINT visit_date_range_ok CHECK (start_date IS NULL OR end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX IF NOT EXISTS visit_the_geom_gist ON cmms.visit USING GIST (the_geom);
CREATE INDEX IF NOT EXISTS visit_type_status_idx ON cmms.visit (type, status);
CREATE INDEX IF NOT EXISTS visit_created_at_idx ON cmms.visit (created_at DESC);
CREATE INDEX IF NOT EXISTS visit_properties_gin ON cmms.visit USING GIN (properties);
CREATE UNIQUE INDEX IF NOT EXISTS visit_ext_visit_id_unique
  ON cmms.visit (ext_visit_id)
  WHERE ext_visit_id IS NOT NULL;

-- =================================================================================
-- TAULA attachment
-- =================================================================================
CREATE TABLE IF NOT EXISTS cmms.attachment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(1024),
  code VARCHAR(255),
  description TEXT,
  content_type VARCHAR(255),
  path TEXT,
  thumbnail_path TEXT,
  size BIGINT,
  attachment_type VARCHAR(50),
  properties jsonb NOT NULL DEFAULT '{}'::jsonb,
  coordinates jsonb,
  the_geom geometry(MultiPolygon, SRID_VALUE),
  uploaded_by VARCHAR(255),
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS attachment_uploaded_at_idx ON cmms.attachment (uploaded_at DESC);
CREATE INDEX IF NOT EXISTS attachment_metadata_gin ON cmms.attachment USING GIN (metadata);
CREATE INDEX IF NOT EXISTS attachment_properties_gin ON cmms.attachment USING GIN (properties);
CREATE INDEX IF NOT EXISTS attachment_the_geom_gist ON cmms.attachment USING GIST (the_geom);

-- =================================================================================
-- TAULA asset_feature_map
--  - Mapping proveïdor (ext_feature_id) <-> feature intern (feature_id) per schema.
--  - feature_type: ARC / NODE / CONNEC / LINK / GULLY
-- =================================================================================
CREATE TABLE IF NOT EXISTS cmms.asset_feature_map (
  id BIGSERIAL PRIMARY KEY,
  ext_feature_id TEXT NOT NULL,
  feature_id INTEGER NOT NULL,
  feature_type VARCHAR(30) NOT NULL CHECK (feature_type IN ('ARC','NODE','CONNEC','LINK','GULLY')),
  schema_name VARCHAR(63) NOT NULL,
  properties jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_by VARCHAR(255),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by VARCHAR(255),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT asset_feature_unique UNIQUE (ext_feature_id, feature_id, feature_type, schema_name)
);

CREATE INDEX IF NOT EXISTS asset_feature_map_ext_feature_id_idx ON cmms.asset_feature_map (ext_feature_id);
CREATE INDEX IF NOT EXISTS asset_feature_map_feature_id_idx ON cmms.asset_feature_map (feature_id);
CREATE INDEX IF NOT EXISTS asset_feature_map_schema_feature_idx ON cmms.asset_feature_map (schema_name, feature_type);
CREATE INDEX IF NOT EXISTS asset_feature_map_properties_gin ON cmms.asset_feature_map USING GIN (properties);

-- =================================================================================
-- TAULA attachment_x_feature
-- =================================================================================
CREATE TABLE IF NOT EXISTS cmms.attachment_x_feature (
  id BIGSERIAL NOT NULL,
  attachment_id UUID NOT NULL,
  asset_feature_map_id BIGINT NOT NULL,
  is_last BOOLEAN NOT NULL DEFAULT false,
  CONSTRAINT attachment_x_feature_pkey PRIMARY KEY (id),
  CONSTRAINT attachment_x_feature_unique UNIQUE (asset_feature_map_id, attachment_id),
  CONSTRAINT attachment_x_feature_attachment_id_fkey FOREIGN KEY (attachment_id) REFERENCES cmms.attachment(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT attachment_x_feature_asset_feature_map_id_fkey FOREIGN KEY (asset_feature_map_id) REFERENCES cmms.asset_feature_map(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS attachment_x_feature_attachment_idx ON cmms.attachment_x_feature (attachment_id);

-- =================================================================================
-- TAULA attachment_x_visit
-- =================================================================================
CREATE TABLE IF NOT EXISTS cmms.attachment_x_visit (
  id BIGSERIAL NOT NULL,
  attachment_id UUID NOT NULL,
  visit_id UUID NOT NULL,
  is_last BOOLEAN NOT NULL DEFAULT false,
  CONSTRAINT attachment_x_visit_pkey PRIMARY KEY (id),
  CONSTRAINT attachment_x_visit_unique UNIQUE (visit_id, attachment_id),
  CONSTRAINT attachment_x_visit_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES cmms.visit(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT attachment_x_visit_attachment_id_fkey FOREIGN KEY (attachment_id) REFERENCES cmms.attachment(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS attachment_x_visit_attachment_idx ON cmms.attachment_x_visit (attachment_id);

-- =================================================================================
-- TAULA visit_x_feature (visites N-N amb actius mapejats)
-- =================================================================================
CREATE TABLE IF NOT EXISTS cmms.visit_x_feature (
  id BIGSERIAL NOT NULL,
  visit_id UUID NOT NULL,
  asset_feature_map_id BIGINT NOT NULL,
  is_last BOOLEAN NOT NULL DEFAULT false,
  CONSTRAINT visit_x_feature_pkey PRIMARY KEY (id),
  CONSTRAINT visit_x_feature_unique UNIQUE (asset_feature_map_id, visit_id),
  CONSTRAINT visit_x_feature_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES cmms.visit(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT visit_x_feature_asset_feature_map_id_fkey FOREIGN KEY (asset_feature_map_id) REFERENCES cmms.asset_feature_map(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS visit_x_feature_visit_idx ON cmms.visit_x_feature (visit_id);

DROP TRIGGER IF EXISTS trg_visit_set_updated_at ON cmms.visit;
CREATE TRIGGER trg_visit_set_updated_at
  BEFORE UPDATE ON cmms.visit
  FOR EACH ROW EXECUTE PROCEDURE cmms.set_updated_at_column();

DROP TRIGGER IF EXISTS trg_asset_feature_map_set_updated_at ON cmms.asset_feature_map;
CREATE TRIGGER trg_asset_feature_map_set_updated_at
  BEFORE UPDATE ON cmms.asset_feature_map
  FOR EACH ROW EXECUTE PROCEDURE cmms.set_updated_at_column();

GRANT SELECT ON ALL TABLES IN SCHEMA cmms TO role_basic;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA cmms TO role_cmms;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA cmms TO role_cmms;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA cmms TO role_cmms;

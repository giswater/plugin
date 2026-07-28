/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = audit, public, pg_catalog;

CREATE TABLE IF NOT EXISTS log (
    id serial8 PRIMARY KEY,
    tstamp timestamp default now(),
    table_name text,
    id_name text,
    feature_id text,
    action text,
    query text,
    sql text NULL,
    old_value json,
    new_value json,
    insert_by text,
    schema text
);

CREATE TABLE IF NOT EXISTS sys_version (
	id serial4 NOT NULL,
	giswater varchar(16) NOT NULL,
	project_type varchar(16) NOT NULL,
	postgres varchar(512) NOT NULL,
	postgis varchar(512) NOT NULL,
	"date" timestamp(6) DEFAULT now() NOT NULL,
	"language" varchar(50) NOT NULL,
	epsg int4 NOT NULL,
	CONSTRAINT sys_version_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS audit_fid_log
(
  id bigserial NOT NULL PRIMARY KEY,
  fid smallint,
  type text,
  fprocess_name text,
  fcount integer,
  groupby text,
  criticity integer,
  tstamp timestamp without time zone DEFAULT now(),
  source json
);

CREATE TABLE IF NOT EXISTS anl_arc
(
  id bigserial NOT NULL PRIMARY KEY,
  arc_id character varying(16) NOT NULL,
  arccat_id character varying(30),
  state integer,
  arc_id_aux character varying(16),
  expl_id integer,
  fid integer NOT NULL,
  cur_user character varying(30) NOT NULL DEFAULT "current_user"(),
  the_geom geometry(LineString,SCHEMA_SRID),
  the_geom_p geometry(Point,SCHEMA_SRID),
  descript text,
  result_id character varying(16),
  node_1 character varying(16),
  node_2 character varying(16),
  sys_type character varying(30),
  code character varying(30),
  tstamp timestamp DEFAULT now(),
  source json
);

CREATE TABLE IF NOT EXISTS anl_node
(
  id bigserial NOT NULL PRIMARY KEY,
  node_id character varying(16) NOT NULL,
  nodecat_id character varying(30),
  state integer,
  num_arcs integer,
  node_id_aux character varying(16),
  nodecat_id_aux character varying(30),
  state_aux integer,
  expl_id integer,
  fid integer NOT NULL,
  cur_user character varying(30) NOT NULL DEFAULT "current_user"(),
  the_geom geometry(Point,SCHEMA_SRID),
  arc_distance numeric(12,3),
  arc_id character varying(16),
  descript text,
  result_id character varying(16),
  sys_type character varying(30),
  code character varying(30),
  tstamp timestamp DEFAULT now(),
  source json
);


CREATE INDEX anl_node_fprocesscat_id_index
  ON anl_node
  USING btree
  (fid);

CREATE INDEX anl_node_index
  ON anl_node
  USING gist
  (the_geom);

CREATE INDEX anl_node_node_id_index
  ON anl_node
  USING btree
  (node_id COLLATE pg_catalog."default");

CREATE INDEX anl_arc_arc_id
  ON anl_arc
  USING btree
  (arc_id COLLATE pg_catalog."default");

CREATE INDEX anl_arc_index
  ON anl_arc
  USING gist
  (the_geom);




CREATE or replace VIEW v_log AS
SELECT insert_by,  count (*) , action, date FROM
(SELECT insert_by, substring(query,0,30)  as action, (substring(date_trunc('day',(tstamp))::text,0,12))::date AS date from log)a
group by insert_by, date, action
ORDER BY date desc;

GRANT ALL ON TABLE v_log TO role_plan;


CREATE OR REPLACE VIEW v_fidlog_aux
AS WITH last_date AS (
         SELECT max(afl.tstamp) as tstamp, source->>'schema' as schema
           FROM audit_fid_log afl
           group by source ->>'schema'
        )
 SELECT a.tstamp::date AS date,
    a.source ->> 'schema' AS schema,
    a.type,
    a.fprocess_name,
    a.criticity,
    a.fcount AS value
   FROM audit_fid_log a,
    last_date
  WHERE a.tstamp = last_date.tstamp and a.source->>'schema' = last_date.schema
  ORDER BY a.tstamp, (a.source ->> 'schema'), a.type;

GRANT ALL ON TABLE v_fidlog_aux TO role_admin;
GRANT INSERT, SELECT ON TABLE v_fidlog_aux TO role_basic;


CREATE OR REPLACE VIEW v_fidlog
AS SELECT v_fidlog_aux.date,
    v_fidlog_aux.schema,
        CASE
            WHEN v_fidlog_aux.type IS NULL THEN 'length'::character varying(100)
            ELSE v_fidlog_aux.type::character varying(100)
        END AS type,
    v_fidlog_aux.criticity,
    sum(v_fidlog_aux.value)::integer AS value
   FROM v_fidlog_aux
  GROUP BY v_fidlog_aux.type, v_fidlog_aux.criticity, v_fidlog_aux.date, v_fidlog_aux.schema
  ORDER BY v_fidlog_aux.date, v_fidlog_aux.schema, (
        CASE
            WHEN v_fidlog_aux.type IS NULL THEN 'length'::character varying(100)
            ELSE v_fidlog_aux.type::character varying(100)
        END);

GRANT ALL ON TABLE v_fidlog TO role_admin;
GRANT INSERT, SELECT ON TABLE v_fidlog TO role_basic;



CREATE OR REPLACE VIEW v_fidlog_table
AS SELECT ct.date_schema[1]::date AS date,
    ct.date_schema[2] AS schema,
    'WARNING'::text AS criticity,
    ct.omdata,
    ct.omtopology,
    ct.grafdata,
    ct.epaconfig,
    ct.epadata,
    ct.epatopology,
    ct.planconfig,
    COALESCE(ct.omdata, 0) + COALESCE(ct.omtopology, 0) + COALESCE(ct.grafdata, 0) + COALESCE(ct.epaconfig, 0) + COALESCE(ct.epadata, 0) + COALESCE(ct.epatopology, 0) + COALESCE(ct.planconfig, 0) AS total,
    (ct.length::numeric / 1000::numeric)::numeric(12,1) AS km,
    (100000::numeric * (COALESCE(ct.omdata, 0) + COALESCE(ct.omtopology, 0) + COALESCE(ct.grafdata, 0) + COALESCE(ct.epaconfig, 0) + COALESCE(ct.epadata, 0) + COALESCE(ct.epatopology, 0) + COALESCE(ct.planconfig, 0))::numeric / ct.length::numeric)::integer AS index
   FROM crosstab('
SELECT ARRAY[date::text, schema], type, value FROM v_fidlog where criticity in (0,2)
'::text, 'VALUES (''Check om-data''), (''Check om-topology''), (''Check graf-data''),(''Check epa-config''), (''Check epa-data''),(''Check epa-topology''), (''Check plan-config''),(''length'')'::text) ct(date_schema text[], omdata integer, omtopology integer, grafdata integer, epaconfig integer, epadata integer, epatopology integer, planconfig integer, length integer)
UNION
 SELECT ct.date_schema[1]::date AS date,
    ct.date_schema[2] AS schema,
    'ERROR'::text AS criticity,
    ct.omdata,
    ct.omtopology,
    ct.grafdata,
    ct.epaconfig,
    ct.epadata,
    ct.epatopology,
    ct.planconfig,
    COALESCE(ct.omdata, 0) + COALESCE(ct.omtopology, 0) + COALESCE(ct.grafdata, 0) + COALESCE(ct.epaconfig, 0) + COALESCE(ct.epadata, 0) + COALESCE(ct.epatopology, 0) + COALESCE(ct.planconfig, 0) AS total,
    (ct.length::numeric / 1000::numeric)::numeric(12,1) AS km,
    (100000::numeric * (COALESCE(ct.omdata, 0) + COALESCE(ct.omtopology, 0) + COALESCE(ct.grafdata, 0) + COALESCE(ct.epaconfig, 0) + COALESCE(ct.epadata, 0) + COALESCE(ct.epatopology, 0) + COALESCE(ct.planconfig, 0))::numeric / ct.length::numeric)::integer AS index
   FROM crosstab('
SELECT ARRAY[date::text, schema], type, value FROM v_fidlog where criticity in (0,3)
'::text, 'VALUES (''Check om-data''), (''Check om-topology''), (''Check graf-data''),(''Check epa-config''), (''Check epa-data''),(''Check epa-topology''), (''Check plan-config''),(''length'')'::text) ct(date_schema text[], omdata integer, omtopology integer, grafdata integer, epaconfig integer, epadata integer, epatopology integer, planconfig integer, length integer)
  ORDER BY 1, 2, 3, 4;

GRANT ALL ON TABLE v_fidlog TO role_admin;
GRANT INSERT, SELECT ON TABLE v_fidlog TO role_basic;


CREATE OR REPLACE VIEW v_fidlog_index
AS SELECT ct.date_schema[1]::date AS date,
    ct.date_schema[2] AS schema,
    a.total AS errors,
    b.total AS warnings,
    a.km,
    ct.index_3 AS err100km,
    ct.index_2 AS war100km,
    concat(ct.index_3, '.', ct.index_2) AS index
   FROM crosstab('SELECT ARRAY[date::text, schema], criticity, index  FROM v_fidlog_table'::text, 'VALUES (''WARNING''), (''ERROR'')'::text) ct(date_schema text[], index_2 integer, index_3 integer)
     JOIN ( SELECT v_fidlog_table.date,
            v_fidlog_table.schema,
            v_fidlog_table.total,
            v_fidlog_table.km,
            v_fidlog_table.index
           FROM v_fidlog_table
          WHERE v_fidlog_table.criticity = 'ERROR'::text) a ON a.date = ct.date_schema[1]::date AND a.schema = ct.date_schema[2]
     JOIN ( SELECT v_fidlog_table.date,
            v_fidlog_table.schema,
            v_fidlog_table.total,
            v_fidlog_table.km,
            v_fidlog_table.index
           FROM v_fidlog_table
          WHERE v_fidlog_table.criticity = 'WARNING'::text) b ON b.date = ct.date_schema[1]::date AND b.schema = ct.date_schema[2]
  WHERE ct.index_3 IS NOT NULL AND ct.index_2 IS NOT NULL;

GRANT ALL ON TABLE v_fidlog_index TO role_admin;
GRANT INSERT, SELECT ON TABLE v_fidlog_index TO role_basic;


SET search_path = PARENT_SCHEMA, public, pg_catalog;

CREATE OR REPLACE VIEW v_log AS
SELECT insert_by,  count (*) , action, date FROM
(SELECT insert_by, substring(query,0,30)  as action, (substring(date_trunc('day',(tstamp))::text,0,12))::date AS date, schema from log)a
group by insert_by, date, action, schema
ORDER BY date desc;

GRANT ALL ON TABLE v_log TO role_plan;


GRANT ALL ON SCHEMA audit TO role_basic; --probably the restriction might be stronger
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO role_basic;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA audit TO role_basic;
GRANT ALL ON SEQUENCE log_id_seq TO role_basic;


CREATE TABLE IF NOT EXISTS snapshot (
    date DATE DEFAULT CURRENT_DATE,
    description TEXT NULL,
    tables TEXT[] NULL,
    "schema" text,
    CONSTRAINT snapshot_pkey PRIMARY KEY (date, "schema")
);

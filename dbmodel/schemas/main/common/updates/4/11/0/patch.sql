/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

CREATE TABLE IF NOT EXISTS temp_view_dependencies (
    id serial PRIMARY KEY,
    batch_id integer NOT NULL,
    cur_user text DEFAULT current_user,
    view_schema text NOT NULL,
    view_name text NOT NULL,
    relkind char(1) NOT NULL DEFAULT 'v',
    view_depth integer NOT NULL,
    view_definition text NOT NULL,
    trigger_definition text,
    tstamp timestamp without time zone DEFAULT now(),
    CONSTRAINT temp_view_dependencies_un UNIQUE (batch_id, view_schema, view_name)
);

CREATE INDEX IF NOT EXISTS temp_view_dependencies_batch_id_depth_idx
    ON temp_view_dependencies (batch_id, view_depth);

DROP VIEW IF EXISTS ve_exploitation;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_muni ON exploitation;
DROP TRIGGER IF EXISTS gw_trg_fk_array_array_table_sector ON exploitation;

ALTER TABLE exploitation DROP COLUMN sector_id;
ALTER TABLE exploitation DROP COLUMN muni_id;

CREATE OR REPLACE VIEW ve_exploitation
AS SELECT e.expl_id,
    e.code,
    e.name,
    e.macroexpl_id,
    e.owner_vdefault,
    e.descript,
    e.lock_level,
    e.active,
    e.the_geom,
    e.created_at,
    e.created_by,
    e.updated_at,
    e.updated_by
FROM exploitation e
WHERE EXISTS (
    SELECT 1
    FROM selector_expl se
    WHERE se.expl_id = e.expl_id AND se.cur_user = CURRENT_USER
) AND e.active IS TRUE;

CREATE TRIGGER gw_trg_edit_exploitation INSTEAD OF INSERT OR DELETE OR UPDATE ON ve_exploitation 
FOR EACH ROW EXECUTE FUNCTION gw_trg_edit_exploitation();

DELETE FROM config_form_fields WHERE formname='ve_exploitation' AND formtype='form_feature' AND columnname='sector_id' AND tabname='tab_none';
DELETE FROM config_form_fields WHERE formname='ve_exploitation' AND formtype='form_feature' AND columnname='muni_id' AND tabname='tab_none';

UPDATE plan_psector SET status = 3 WHERE status = 4;

ALTER TABLE plan_typevalue DISABLE TRIGGER USER;
DELETE FROM plan_typevalue WHERE typevalue='psector_status' AND id='4';
ALTER TABLE plan_typevalue ENABLE TRIGGER USER;

INSERT INTO sys_function (id, function_name, project_type, function_type, input_params, return_type, descript, sys_role, sample_query, "source", function_alias)
VALUES (3542, 'gw_fct_admin_manage_view_dependencies', 'utils', 'function', 'json', 'json',
'Recursively discovers dependent views on parent editable views across all database schemas, saves their definitions, drops them in safe order and restores them after parent recreation',
'role_admin', NULL, 'core', NULL)
ON CONFLICT (id) DO NOTHING;

UPDATE sys_param_user
SET descript = 'If true, disable gw_trg_array_fk_array_table trigger logic on all tables'
WHERE id = 'edit_disable_arc_fkarray';


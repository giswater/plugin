/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- Parent-side trigger function. CREATE TRIGGER passes the id column name
-- (node_id, arc_id, ...) as TG_ARGV[0]. The parent schema and feature type
-- come from TG_TABLE_SCHEMA / TG_TABLE_NAME, so a schema rename keeps working.
-- DELETE orphans the live mapping. UPDATE of the id rewrites feature_id.
-- SECURITY DEFINER: feature editors have no write grant on cmms.
CREATE OR REPLACE FUNCTION cmms.gw_trg_cmms_feature_sync()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = cmms, public, pg_catalog
AS $function$
DECLARE
    v_id_column text;
    v_feature_type text;
    v_old_id integer;
    v_new_id integer;
BEGIN
    IF TG_NARGS < 1 THEN
        RAISE EXCEPTION 'cmms.gw_trg_cmms_feature_sync requires the id column name';
    END IF;

    v_id_column := TG_ARGV[0];
    v_feature_type := upper(TG_TABLE_NAME);

    IF TG_OP = 'DELETE' THEN
        v_old_id := (to_jsonb(OLD) ->> v_id_column)::integer;
        UPDATE cmms.asset_feature_map
        SET feature_deleted_at = now()
        WHERE schema_name = TG_TABLE_SCHEMA
            AND feature_type = v_feature_type
            AND feature_id = v_old_id
            AND feature_deleted_at IS NULL;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        v_old_id := (to_jsonb(OLD) ->> v_id_column)::integer;
        v_new_id := (to_jsonb(NEW) ->> v_id_column)::integer;
        UPDATE cmms.asset_feature_map
        SET feature_id = v_new_id
        WHERE schema_name = TG_TABLE_SCHEMA
            AND feature_type = v_feature_type
            AND feature_id = v_old_id
            AND feature_deleted_at IS NULL;
        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$function$;

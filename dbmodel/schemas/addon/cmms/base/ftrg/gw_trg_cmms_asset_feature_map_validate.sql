/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- A live asset_feature_map row must point at a real parent feature.
-- Orphan rows (feature_deleted_at set) skip the check so history can outlive the feature.
-- SECURITY DEFINER: role_cmms writes this table but has no SELECT on ws/ud.
-- role_system owns those tables.
CREATE OR REPLACE FUNCTION cmms.gw_trg_cmms_asset_feature_map_validate()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = cmms, public, pg_catalog
AS $function$
DECLARE
    v_relation regclass;
    v_id_column text;
    v_exists boolean;
BEGIN
    IF NEW.feature_deleted_at IS NOT NULL THEN
        RETURN NEW;
    END IF;

    v_id_column := lower(NEW.feature_type) || '_id';
    v_relation := to_regclass(format('%I.%I', NEW.schema_name, lower(NEW.feature_type)));
    IF v_relation IS NULL THEN
        RAISE EXCEPTION 'cmms asset_feature_map target %.% does not exist',
            NEW.schema_name, lower(NEW.feature_type)
            USING ERRCODE = 'foreign_key_violation';
    END IF;

    EXECUTE format('SELECT EXISTS (SELECT 1 FROM %s WHERE %I = $1)', v_relation, v_id_column)
        INTO v_exists
        USING NEW.feature_id;
    IF NOT v_exists THEN
        RAISE EXCEPTION 'cmms asset_feature_map target %.% %=% does not exist',
            NEW.schema_name, lower(NEW.feature_type), v_id_column, NEW.feature_id
            USING ERRCODE = 'foreign_key_violation';
    END IF;

    RETURN NEW;
END;
$function$;

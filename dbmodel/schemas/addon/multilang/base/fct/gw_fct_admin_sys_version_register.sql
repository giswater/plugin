/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION multilang.gw_fct_admin_sys_version_register(p_data json)
RETURNS json AS
$BODY$
DECLARE
    v_gwversion text;
    v_language text;
    v_projecttype text;
    v_epsg integer;
    v_isnew boolean;
    v_creation_profile text;
    v_infer_parents boolean;
    v_parent_schema text;
    v_merge jsonb;
    v_prev record;
    v_environment jsonb;
    v_addparam jsonb;
BEGIN
    SET search_path = multilang, public;

    v_gwversion := (p_data -> 'data') ->> 'gwVersion';
    v_language := COALESCE((p_data -> 'client') ->> 'lang', 'en_US');
    v_projecttype := (p_data -> 'data') ->> 'projectType';
    v_epsg := NULLIF((p_data -> 'data') ->> 'epsg', '')::integer;
    v_isnew := lower(COALESCE((p_data -> 'data') ->> 'isNewProject', 'false')) IN ('true', 't', '1');
    v_creation_profile := NULLIF((p_data -> 'data') ->> 'creationProfile', '');
    v_infer_parents := lower(COALESCE((p_data -> 'data') ->> 'inferParentsFromConfig', 'false')) IN ('true', 't', '1');
    v_parent_schema := NULLIF((p_data -> 'data') ->> 'parentSchema', '');
    v_merge := COALESCE((p_data -> 'data') -> 'mergeAddparam', '{}'::json)::jsonb;
    v_environment := jsonb_build_object('postgres', version(), 'postgis', postgis_version());

    SELECT * INTO v_prev FROM multilang.sys_version ORDER BY id DESC LIMIT 1;

    IF v_gwversion IS NULL AND v_prev IS NOT NULL THEN
        v_gwversion := v_prev.giswater;
    END IF;

    IF v_isnew IS NOT TRUE AND v_prev IS NOT NULL THEN
        v_language := COALESCE(v_prev.language, v_language);
        v_epsg := COALESCE(v_epsg, v_prev.epsg);
        v_projecttype := COALESCE(v_projecttype, v_prev.project_type);
        v_creation_profile := COALESCE(v_creation_profile, v_prev.addparam -> 'environment' ->> 'creation_profile');
    ELSIF v_isnew IS TRUE AND v_epsg IS NULL THEN
        v_epsg := 25831;
    END IF;

    IF v_creation_profile IS NOT NULL THEN
        v_environment := v_environment || jsonb_build_object('creation_profile', v_creation_profile);
    END IF;

    v_addparam := COALESCE(v_prev.addparam, '{}'::jsonb);
    v_addparam := jsonb_set(
        v_addparam,
        '{environment}',
        COALESCE(v_addparam -> 'environment', '{}'::jsonb) || v_environment,
        true
    );

    IF v_merge IS NOT NULL AND v_merge <> '{}'::jsonb THEN
        v_addparam := v_addparam || v_merge;
    END IF;

    IF v_parent_schema IS NOT NULL THEN
        v_addparam := jsonb_set(
            v_addparam,
            '{parent_schemas}',
            (
                SELECT COALESCE(jsonb_agg(DISTINCT elem), '[]'::jsonb)
                FROM jsonb_array_elements_text(
                    COALESCE(v_addparam -> 'parent_schemas', '[]'::jsonb) || to_jsonb(v_parent_schema)
                ) AS elem
            ),
            true
        );
    END IF;

    INSERT INTO multilang.sys_version (giswater, project_type, postgres, postgis, language, epsg, addparam)
    VALUES (
        v_gwversion,
        upper(COALESCE(v_projecttype, 'MULTILANG')),
        version(),
        postgis_version(),
        v_language,
        v_epsg,
        v_addparam
    );

    RETURN json_build_object('status', 'Accepted', 'version', v_gwversion);
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

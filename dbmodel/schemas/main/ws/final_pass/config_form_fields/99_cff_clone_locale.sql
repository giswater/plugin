/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = "SCHEMA_NAME", public, pg_catalog;

DO $clone$
DECLARE
    rec record;
BEGIN
    FOR rec IN
        SELECT id, child_layer, lower(feature_type::text) AS feature_type
        FROM cat_feature
        WHERE child_layer IS NOT NULL
    LOOP
        PERFORM gw_fct_admin_manage_child_config(json_build_object(
            'client', json_build_object('device', 4, 'infoType', 1, 'lang', 'ES'),
            'form', json_build_object(),
            'feature', json_build_object('catFeature', rec.id),
            'data', json_build_object(
                'view_name', rec.child_layer,
                'feature_type', rec.feature_type
            )
        ));
    END LOOP;
END
$clone$;

ALTER TABLE config_form_fields ENABLE TRIGGER gw_trg_config_control;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- Parent-side views. Each feature table that exists is one UNION ALL branch,
-- joined to cmms on sys_code. gully is absent on ws, so the branch list is
-- built here instead of written out. The view stores the parent tables as
-- oids, so a schema rename keeps resolving them.
-- v_cmms_visit and v_cmms_attachment are one row per visit or attachment.
-- Their joins run at read time, so a feature inserted later is included.
CREATE OR REPLACE FUNCTION cmms.gw_fct_cmms_create_parent_views(p_schema text)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    v_tables text[] := ARRAY['node', 'arc', 'connec', 'link', 'gully', 'element'];
    v_table text;
    v_id_column text;
    v_feature_type text;
    v_visit_parts text[] := ARRAY[]::text[];
    v_attachment_parts text[] := ARRAY[]::text[];
    v_visit_exists text[] := ARRAY[]::text[];
    v_attachment_exists text[] := ARRAY[]::text[];
BEGIN
    IF p_schema IS NULL OR btrim(p_schema) = '' THEN
        RAISE EXCEPTION 'cmms parent schema is required';
    END IF;

    FOREACH v_table IN ARRAY v_tables
    LOOP
        IF to_regclass(format('%I.%I', p_schema, v_table)) IS NULL THEN
            CONTINUE;
        END IF;
        v_id_column := v_table || '_id';
        v_feature_type := upper(v_table);

        v_visit_parts := v_visit_parts || format(
            'SELECT f.%1$I::text AS feature_id, '
            '%2$L::varchar(30) AS feature_type, '
            'v.id AS visit_id, v.ext_visit_id, v.type, v.status, v.title, v.description, '
            'v.start_date, v.end_date, '
            'EXISTS (SELECT 1 FROM cmms.attachment_x_visit AS ax WHERE ax.visit_id = v.id) AS has_attachment '
            'FROM %3$I.%4$I AS f '
            'JOIN cmms.visit_x_feature AS vx ON vx.sys_code = f.sys_code '
            'JOIN cmms.visit AS v ON v.id = vx.visit_id',
            v_id_column, v_feature_type, p_schema, v_table
        );

        v_attachment_parts := v_attachment_parts || format(
            'SELECT f.%1$I::text AS feature_id, '
            '%2$L::varchar(30) AS feature_type, '
            'NULL::uuid AS visit_id, '
            'a.id AS attachment_id, a.name, a.attachment_type, a.content_type, a.description, '
            'a.uploaded_at, a.uploaded_by, a.path, a.thumbnail_path '
            'FROM %3$I.%4$I AS f '
            'JOIN cmms.attachment_x_feature AS axf ON axf.sys_code = f.sys_code '
            'JOIN cmms.attachment AS a ON a.id = axf.attachment_id',
            v_id_column, v_feature_type, p_schema, v_table
        );
        v_attachment_parts := v_attachment_parts || format(
            'SELECT f.%1$I::text AS feature_id, '
            '%2$L::varchar(30) AS feature_type, '
            'vx.visit_id, '
            'a.id AS attachment_id, a.name, a.attachment_type, a.content_type, a.description, '
            'a.uploaded_at, a.uploaded_by, a.path, a.thumbnail_path '
            'FROM %3$I.%4$I AS f '
            'JOIN cmms.visit_x_feature AS vx ON vx.sys_code = f.sys_code '
            'JOIN cmms.attachment_x_visit AS axv ON axv.visit_id = vx.visit_id '
            'JOIN cmms.attachment AS a ON a.id = axv.attachment_id',
            v_id_column, v_feature_type, p_schema, v_table
        );

        v_visit_exists := v_visit_exists || format(
            'EXISTS ('
            'SELECT 1 FROM cmms.visit_x_feature AS vx '
            'JOIN %1$I.%2$I AS f ON f.sys_code = vx.sys_code '
            'WHERE vx.visit_id = v.id)',
            p_schema, v_table
        );
        v_attachment_exists := v_attachment_exists || format(
            'EXISTS ('
            'SELECT 1 FROM cmms.attachment_x_feature AS axf '
            'JOIN %1$I.%2$I AS f ON f.sys_code = axf.sys_code '
            'WHERE axf.attachment_id = a.id)',
            p_schema, v_table
        );
        v_attachment_exists := v_attachment_exists || format(
            'EXISTS ('
            'SELECT 1 FROM cmms.attachment_x_visit AS axv '
            'JOIN cmms.visit_x_feature AS vx ON vx.visit_id = axv.visit_id '
            'JOIN %1$I.%2$I AS f ON f.sys_code = vx.sys_code '
            'WHERE axv.attachment_id = a.id)',
            p_schema, v_table
        );
    END LOOP;

    IF cardinality(v_visit_parts) = 0 THEN
        RAISE EXCEPTION 'cmms parent % has no feature tables', p_schema;
    END IF;

    EXECUTE format('DROP VIEW IF EXISTS %I.v_cmms_attachment', p_schema);
    EXECUTE format('DROP VIEW IF EXISTS %I.v_cmms_visit', p_schema);
    EXECUTE format('DROP VIEW IF EXISTS %I.v_ui_cmms_attachment', p_schema);
    EXECUTE format('DROP VIEW IF EXISTS %I.v_ui_cmms_visit', p_schema);
    EXECUTE format(
        'CREATE VIEW %I.v_ui_cmms_visit AS %s',
        p_schema, array_to_string(v_visit_parts, ' UNION ALL ')
    );
    EXECUTE format(
        'CREATE VIEW %I.v_ui_cmms_attachment AS %s',
        p_schema, array_to_string(v_attachment_parts, ' UNION ALL ')
    );
    EXECUTE format(
        'CREATE VIEW %I.v_cmms_visit AS '
        'SELECT v.id, v.ext_visit_id, v.type, v.status, v.title, v.description, '
        'v.start_date, v.end_date, v.the_geom '
        'FROM cmms.visit AS v WHERE %s',
        p_schema, array_to_string(v_visit_exists, ' OR ')
    );
    EXECUTE format(
        'CREATE VIEW %I.v_cmms_attachment AS '
        'SELECT a.id, a.name, a.code, a.attachment_type, a.content_type, a.description, '
        'a.uploaded_at, a.uploaded_by, a.path, a.thumbnail_path, a.the_geom '
        'FROM cmms.attachment AS a WHERE %s',
        p_schema, array_to_string(v_attachment_exists, ' OR ')
    );
END;
$function$;

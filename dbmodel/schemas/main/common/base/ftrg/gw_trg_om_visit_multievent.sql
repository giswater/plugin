/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2944

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_om_visit_multievent()
RETURNS trigger AS
$BODY$
DECLARE
    visit_class integer;
    v_sql varchar;
    v_parameters record;
    v_new_value_param text;
    v_query_text text;
    visit_table text;
    v_visit_type integer;
    v_pluginlot boolean;
    v_unit_id integer;
    v_num_elem_visit text;
    v_feature_id bigint;
    v_id_field text;
    v_uuid_field text;
    v_link_table text;
    v_uuid uuid;
    v_new_json jsonb;

    v_cols text;
    v_vals text;
    v_sets text;
    v_col record;
    v_class_feature_type text;

BEGIN

    EXECUTE 'SET search_path TO ' || quote_literal(TG_TABLE_SCHEMA) || ', public';

    -- Resolve class with dual mode:
    -- 1) optional trigger argument (TG_ARGV[0]) as explicit override
    -- 2) fallback to row class_id when no argument is provided
    IF TG_NARGS > 0 AND NULLIF(TG_ARGV[0], '') IS NOT NULL THEN
        visit_class := TG_ARGV[0]::integer;
    ELSIF TG_OP = 'DELETE' THEN
        visit_class := OLD.class_id;
    ELSE
        visit_class := NEW.class_id;
    END IF;

    IF TG_OP = 'DELETE' THEN
        v_new_json := to_jsonb(OLD);
    ELSE
        v_new_json := to_jsonb(NEW);
    END IF;

    SELECT lower(feature_type)
    INTO v_class_feature_type
    FROM config_visit_class
    WHERE id = visit_class;

    IF v_class_feature_type = 'all' THEN
        IF (v_new_json ? 'node_id') AND NULLIF(v_new_json->>'node_id','') IS NOT NULL THEN
            visit_table := 'node';
        ELSIF (v_new_json ? 'arc_id') AND NULLIF(v_new_json->>'arc_id','') IS NOT NULL THEN
            visit_table := 'arc';
        ELSIF (v_new_json ? 'connec_id') AND NULLIF(v_new_json->>'connec_id','') IS NOT NULL THEN
            visit_table := 'connec';
        ELSIF (v_new_json ? 'link_id') AND NULLIF(v_new_json->>'link_id','') IS NOT NULL THEN
            visit_table := 'link';
        ELSIF (v_new_json ? 'gully_id') AND NULLIF(v_new_json->>'gully_id','') IS NOT NULL THEN
            visit_table := 'gully';
        ELSE
            RAISE EXCEPTION 'Visit class % has feature_type=ALL but no feature id was provided in trigger row', visit_class;
        END IF;
    ELSE
        visit_table := v_class_feature_type;
    END IF;

    v_id_field   := visit_table || '_id';
    v_uuid_field := visit_table || '_uuid';
    v_link_table := 'om_visit_x_' || visit_table;

    SELECT visit_type
    INTO v_visit_type
    FROM config_visit_class
    WHERE id = visit_class;

    SELECT upper(value::json->>'lotManage')
    INTO v_pluginlot
    FROM config_param_system
    WHERE parameter = 'plugin_lotmanage';

    IF TG_OP = 'INSERT' THEN

        IF NEW.visit_id IS NULL THEN
            PERFORM setval('"SCHEMA_NAME".om_visit_id_seq', (SELECT max(id) FROM om_visit), true);
            NEW.visit_id := nextval('om_visit_id_seq');
        END IF;

        IF NEW.startdate IS NULL THEN
            NEW.startdate := left(date_trunc('second', now())::text, 19);
        END IF;

        IF NEW.status IS NULL THEN
            NEW.status := 4;
        END IF;

        -- force enddate for planned visits
        IF NEW.status = 4 AND NEW.enddate IS NULL AND v_visit_type = 1 THEN
            NEW.enddate := left(date_trunc('second', now())::text, 19);
        END IF;

        v_new_json := to_jsonb(NEW);
        v_cols := '';
        v_vals := '';

        FOR v_col IN
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = TG_TABLE_SCHEMA
              AND table_name = 'om_visit'
            ORDER BY ordinal_position
        LOOP
            IF v_col.column_name = 'id' THEN
                v_cols := v_cols || CASE WHEN v_cols <> '' THEN ', ' ELSE '' END || quote_ident(v_col.column_name);
                v_vals := v_vals || CASE WHEN v_vals <> '' THEN ', ' ELSE '' END || '($1).visit_id';
            ELSIF v_new_json ? v_col.column_name THEN
                v_cols := v_cols || CASE WHEN v_cols <> '' THEN ', ' ELSE '' END || quote_ident(v_col.column_name);

                IF v_col.column_name = 'the_geom' AND visit_table = 'arc' THEN
                    v_vals := v_vals || CASE WHEN v_vals <> '' THEN ', ' ELSE '' END || '($1).the_geom';
                ELSIF v_col.column_name = 'startdate' THEN
                    v_vals := v_vals || CASE WHEN v_vals <> '' THEN ', ' ELSE '' END || '($1).startdate::timestamp';
                ELSE
                    v_vals := v_vals || CASE WHEN v_vals <> '' THEN ', ' ELSE '' END || format('($1).%I', v_col.column_name);
                END IF;
            END IF;
        END LOOP;

        v_sql := format('INSERT INTO om_visit (%s) VALUES (%s)', v_cols, v_vals);
        EXECUTE v_sql USING NEW;

        -- Get related parameters(events) from visit_class
        v_query_text := '
            SELECT *
            FROM config_visit_parameter
            JOIN config_visit_class_x_parameter
              ON config_visit_class_x_parameter.parameter_id = config_visit_parameter.id
            JOIN config_visit_class
              ON config_visit_class.id = config_visit_class_x_parameter.class_id
            WHERE config_visit_class.id = ' || visit_class || '
              AND config_visit_class.ismultievent IS TRUE
              AND config_visit_parameter.active IS TRUE
              AND config_visit_class_x_parameter.active IS TRUE';

        FOR v_parameters IN EXECUTE v_query_text
        LOOP
            EXECUTE 'SELECT $1.' || v_parameters.id
            USING NEW
            INTO v_new_value_param;

            -- exception to manage parameter 'num_elem_visit'
            IF v_parameters.id = 'num_elem_visit' THEN
                IF visit_table = 'arc' THEN
                    SELECT unit_id INTO v_unit_id
                    FROM om_visit_lot_x_arc
                    WHERE arc_id = NEW.arc_id AND lot_id = NEW.lot_id;
                ELSIF visit_table = 'node' THEN
                    SELECT unit_id INTO v_unit_id
                    FROM om_visit_lot_x_node
                    WHERE node_id = NEW.node_id AND lot_id = NEW.lot_id;
                END IF;

                SELECT string_agg(concat, ' ')
                INTO v_num_elem_visit
                FROM (
                    SELECT concat('trams:', array_agg(arc_id))
                    FROM om_visit_lot_x_arc
                    WHERE unit_id = v_unit_id AND lot_id = NEW.lot_id
                    UNION
                    SELECT concat('nodes:', array_agg(node_id))
                    FROM om_visit_lot_x_node
                    WHERE unit_id = v_unit_id AND lot_id = NEW.lot_id
                ) b;

                v_new_value_param := v_num_elem_visit;
            END IF;

            EXECUTE 'INSERT INTO om_visit_event (visit_id, parameter_id, value) VALUES ($1, $2, $3)'
            USING NEW.visit_id, v_parameters.id, v_new_value_param;
        END LOOP;

        -- insert into om_visit_x_* tables
        v_new_json := to_jsonb(NEW);

        IF v_new_json ? v_uuid_field THEN
            v_uuid := (v_new_json ->> v_uuid_field)::uuid;

            IF v_uuid IS NOT NULL THEN
                EXECUTE format('SELECT %I FROM %I WHERE uuid = $1', v_id_field, visit_table)
                INTO v_feature_id
                USING v_uuid;
            END IF;
        END IF;

        IF v_feature_id IS NOT NULL THEN
            v_sql := format(
                'INSERT INTO %I (visit_id, %I, %I) VALUES ($1, $2, $3)',
                v_link_table, v_id_field, v_uuid_field
            );
            EXECUTE v_sql USING NEW.visit_id, v_feature_id, v_uuid;
        ELSE
            v_sql := format(
                'INSERT INTO %I (visit_id, %I) VALUES ($1, ($2).%I)',
                v_link_table, v_id_field, v_id_field
            );
            EXECUTE v_sql USING NEW.visit_id, NEW, v_id_field;
        END IF;

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        v_new_json := to_jsonb(NEW);
        v_sets := '';

        FOR v_col IN
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = TG_TABLE_SCHEMA
              AND table_name = 'om_visit'
              AND column_name <> 'id'
            ORDER BY ordinal_position
        LOOP
            IF v_new_json ? v_col.column_name THEN
                IF v_col.column_name = 'the_geom' AND visit_table = 'arc' THEN
                    v_sets := v_sets || CASE WHEN v_sets <> '' THEN ', ' ELSE '' END ||
                              format('%I = ST_CENTROID(($1).the_geom)', v_col.column_name);
                ELSIF v_col.column_name = 'startdate' THEN
                    v_sets := v_sets || CASE WHEN v_sets <> '' THEN ', ' ELSE '' END ||
                              format('%I = ($1).startdate::timestamp', v_col.column_name);
                ELSE
                    v_sets := v_sets || CASE WHEN v_sets <> '' THEN ', ' ELSE '' END ||
                              format('%I = ($1).%I', v_col.column_name, v_col.column_name);
                END IF;
            END IF;
        END LOOP;

        v_sql := format('UPDATE om_visit SET %s WHERE id = COALESCE(($1).visit_id, ($1).id)', v_sets);
        EXECUTE v_sql USING NEW;

        -- Get related parameters(events) from visit_class
        v_query_text := '
            SELECT *
            FROM config_visit_parameter
            JOIN config_visit_class_x_parameter
              ON config_visit_class_x_parameter.parameter_id = config_visit_parameter.id
            JOIN config_visit_class
              ON config_visit_class.id = config_visit_class_x_parameter.class_id
            WHERE config_visit_class.id = ' || visit_class || '
              AND config_visit_class.ismultievent IS TRUE
              AND config_visit_parameter.active IS TRUE
              AND config_visit_class_x_parameter.active IS TRUE';

        FOR v_parameters IN EXECUTE v_query_text
        LOOP
            EXECUTE 'SELECT $1.' || v_parameters.id
            USING NEW
            INTO v_new_value_param;

            EXECUTE 'UPDATE om_visit_event SET value = $3 WHERE visit_id = $1 AND parameter_id = $2'
            USING NEW.visit_id, v_parameters.id, v_new_value_param;
        END LOOP;

        -- set enddate when change to closed status (4)
        IF NEW.status = 4 AND OLD.status < 4 THEN
            NEW.enddate := left(date_trunc('second', now())::text, 19);
            UPDATE om_visit SET enddate = NEW.enddate WHERE id = NEW.visit_id;
        END IF;

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        DELETE FROM om_visit CASCADE WHERE id = OLD.visit_id;
        RETURN NULL;
    END IF;

END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3480

CREATE OR REPLACE FUNCTION cm.gw_trg_cm_lot_x_feature()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    v_feature_type TEXT := TG_ARGV[0];
    v_feature_id_column TEXT;
    v_feature_column TEXT;
    v_view_name TEXT;
    v_feature_child_type TEXT;
    v_querytext TEXT;
    v_feature_id_value INTEGER;
    v_lot_id INTEGER;
    v_row RECORD;
    v_dest_table_name TEXT;
    v_source_columns TEXT;
    v_dest_columns TEXT;
    v_user_role_name TEXT;
    v_field_role_name TEXT := 'role_cm_field';
    v_prev_search_path text;
	v_isqfield BOOLEAN;
	v_campaign_id TEXT;
	v_rec RECORD;
	v_exists BOOLEAN;
	v_arc_type text;
BEGIN
    -- Save and set search_path transaction-locally
    v_prev_search_path := current_setting('search_path');
    PERFORM set_config('search_path', format('%I, PARENT_SCHEMA, public', TG_TABLE_SCHEMA), true);

    -- Part 1: Logic for BEFORE trigger. Sets 'action' before the row is saved.
    IF TG_WHEN = 'BEFORE' THEN
		v_feature_id_column := v_feature_type || '_id';
        IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
            -- Get the role for the current user
            SELECT rolname INTO v_user_role_name 
            FROM pg_user u JOIN pg_auth_members m ON (m.member = u.usesysid) 
            JOIN pg_roles r ON (r.oid = m.roleid)
            WHERE u.usename = current_user and rolname = 'role_cm_field';

            -- Only proceed if the user's role is 'role_cm_field'
            --IF v_user_role_name = v_field_role_name THEN
				EXECUTE format('SELECT ($1).%I < 0', v_feature_id_column)
			        INTO v_isqfield
			        USING NEW;
                IF TG_OP = 'INSERT' THEN
				    IF v_isqfield is false THEN
				        NEW.action := NULL;
				    ELSE
				        NEW.action := 1;
				    END IF;
                ELSIF TG_OP = 'UPDATE' AND NEW IS DISTINCT FROM OLD THEN
					IF NEW.action IS DISTINCT FROM 3 AND NEW.action IS DISTINCT FROM 4 THEN
						IF v_isqfield is false THEN
	                    	NEW.action = 2;
						ELSE
							NEW.action = 1;
						END IF;
					END IF;
                END IF;
            --END IF;

			PERFORM set_config('search_path', v_prev_search_path, true);
	        RETURN NEW; -- Return the (potentially modified) row
        
		ELSIF TG_OP = 'DELETE' THEN

			v_lot_id := OLD.lot_id;
			EXECUTE format('SELECT ($1).%I', v_feature_id_column) INTO v_feature_id_value USING OLD;
			EXECUTE format('SELECT ($1).%I < 0', v_feature_id_column)
			        INTO v_isqfield
			        USING OLD;
			
			PERFORM set_config('search_path', v_prev_search_path, true);
			IF v_isqfield is true then
				v_querytext := format('DELETE FROM cm.%I WHERE campaign_id = $1::int AND %I = $2::int', concat('om_campaign_x_', v_feature_type), v_feature_id_column);
				EXECUTE 'SELECT campaign_id FROM cm.om_campaign_lot WHERE lot_id = $1' INTO v_campaign_id USING v_lot_id;
				EXECUTE v_querytext USING v_campaign_id, v_feature_id_value;
				RETURN OLD;
			ELSE
				IF OLD.action = 4 THEN
					FOR v_rec IN SELECT t.table_name, c.column_name AS id_column FROM information_schema.tables t
								JOIN information_schema.columns c ON t.table_schema = c.table_schema AND t.table_name = c.table_name
								WHERE t.table_type = 'BASE TABLE' AND t.table_name LIKE 'PARENT_SCHEMA_%' AND t.table_schema = 'cm' AND c.ordinal_position = 3
					LOOP
						EXECUTE format('select 1 FROM cm.%I WHERE %I = $1.%I', v_rec.table_name, v_rec.id_column, v_feature_id_column) USING OLD INTO v_exists;
	
						IF v_exists IS NOT NULL THEN
							v_arc_type = v_rec.table_name;
							exit;
						END IF;
					END LOOP;
					RETURN OLD;
				END IF;
				EXECUTE format('UPDATE cm.om_campaign_lot_x_%s SET "action" = 3 where %I = $1', v_feature_type, v_feature_id_column) USING v_feature_id_value;
				RETURN NULL;
			END IF;
		END IF;
        
    END IF;

    -- Part 2: Logic for AFTER trigger. Copies/deletes data after the row is saved.
    IF TG_WHEN = 'AFTER' THEN
        v_feature_id_column := v_feature_type || '_id';
        
        IF TG_OP = 'INSERT' THEN
            v_lot_id := NEW.lot_id;
            EXECUTE format('SELECT ($1).%I', v_feature_id_column) INTO v_feature_id_value USING NEW;
        END IF;
		
		-- set status ON GOING when the first object is reviewed
		IF (SELECT COUNT(*) FROM (SELECT 1 FROM om_campaign_lot_x_node WHERE lot_id = NEW.lot_id AND status = 3
		    UNION ALL
		    SELECT 1 FROM om_campaign_lot_x_arc WHERE lot_id = NEW.lot_id AND status = 3) t) = 1 THEN
		  UPDATE om_campaign_lot
		  SET status = 4
		  WHERE lot_id = NEW.lot_id;
		END IF;

        IF TG_OP = 'INSERT' THEN
            v_querytext := format(
                'SELECT c.%s_type ' ||
                'FROM PARENT_SCHEMA.%s p ' ||
                'JOIN PARENT_SCHEMA.cat_%s c ON p.%scat_id = c.id ' ||
                'WHERE p.%s_id = $1',
                v_feature_type, v_feature_type, v_feature_type, v_feature_type, v_feature_type
            );
            EXECUTE v_querytext INTO v_feature_child_type USING v_feature_id_value;

            IF v_feature_child_type IS NOT NULL THEN
                v_dest_table_name := format('PARENT_SCHEMA_%s', lower(v_feature_child_type));
                IF TG_OP = 'INSERT' THEN
                    v_view_name := format('ve_%s_%s', v_feature_type, lower(v_feature_child_type));
                    SELECT string_agg(quote_ident(column_name), ', '), string_agg('vn.' || quote_ident(column_name), ', ')
                    INTO v_dest_columns, v_source_columns
                    FROM information_schema.columns
                    WHERE table_schema = 'PARENT_SCHEMA' AND table_name = v_view_name AND column_name <> 'the_geom';

                    IF v_dest_columns IS NOT NULL THEN
                        v_querytext := format(
                            'INSERT INTO cm.%I (id, lot_id, %s) ' ||
                            'SELECT nextval(''cm.%I_id_seq''::regclass), v.lot_id, %s FROM cm.om_campaign_lot_x_%s v JOIN PARENT_SCHEMA.%I vn ON vn.%I::integer = v.%I WHERE v.lot_id = $1 AND v.%I = $2',
                            v_dest_table_name, v_dest_columns, v_dest_table_name, v_source_columns,
                            v_feature_type, v_view_name, v_feature_id_column, v_feature_id_column, v_feature_id_column
                        );
                        EXECUTE v_querytext USING v_lot_id, v_feature_id_value;
                    END IF;
                END IF;
            END IF;
        END IF;
        IF TG_OP = 'INSERT' THEN 
            PERFORM set_config('search_path', v_prev_search_path, true);
            RETURN NEW; 
        END IF;
    END IF;

    PERFORM set_config('search_path', v_prev_search_path, true);
    RETURN NULL; -- Should not happen
EXCEPTION WHEN OTHERS THEN
    PERFORM set_config('search_path', v_prev_search_path, true);
    RAISE;
END;
$function$;

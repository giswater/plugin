/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3504

CREATE OR REPLACE FUNCTION cm.gw_fct_cm_check_catalogs(p_data json)
RETURNS json AS
$BODY$

/*EXAMPLE
SELECT cm.gw_fct_cm_check_catalogs('{"data":{"projectType":"CM","version":"4.0","fromProduction":false}}'::json);
*/

DECLARE
    v_project_type text;
    v_version text;
    v_from_production boolean;
    v_campaign_id text;
    v_lot_id text;
    v_current_role text;
    v_error_context text;
    v_result json;
    v_log text;
    v_catalog_record record;
    v_feature_record record;
    v_rec_subtype record;
    v_missing_catalog text;
    v_catalog_id integer;
    v_count integer;
    v_new_needed_count integer := 0;
    v_feature_type text;
    v_subtype text;
    v_form_name text;
    v_querytext text;
    v_feature_id text;
    v_new_catalog_id text;
    v_view_exists boolean;
    v_processed_combinations text[] := ARRAY[]::text[];
    v_combination_key text;
    v_prev_search_path text;
    
BEGIN
    -- Save current search_path and switch to cm (transaction-local)
    v_prev_search_path := current_setting('search_path');
    PERFORM set_config('search_path', 'cm,public', true);
    -- Initialize variables
    v_project_type := COALESCE((p_data->>'data')::json->>'projectType', 'WS');
    v_version := COALESCE((p_data->>'data')::json->>'version', '4.0');
    v_from_production := COALESCE((p_data->>'data')::json->>'fromProduction', 'false')::boolean;
    v_campaign_id := COALESCE((p_data->>'data')::json->>'campaign_id', NULL);
    v_lot_id := COALESCE((p_data->>'data')::json->>'lot_id', NULL);
    v_log := '';
    
    -- Get current user role
    BEGIN
        SELECT r.rolname AS role_name INTO v_current_role
        FROM pg_roles r
        JOIN pg_auth_members m ON r.oid = m.roleid
        JOIN pg_roles u ON u.oid = m.member 
        WHERE u.rolname = current_user AND r.rolname ILIKE '%cm%';
    EXCEPTION WHEN OTHERS THEN
        v_current_role := NULL;
    END;
    
    -- Check if user has admin role ONLY when trying to create catalogs (fromProduction = true)
    IF v_from_production AND v_current_role != 'role_addon_cm_admin' THEN
        RETURN json_build_object(
            'status', 'Failed',
            'message', 'Access denied. Only role_addon_cm_admin can create catalog entries.',
            'body', json_build_object('log', 'ERROR: Insufficient privileges. User must have role_addon_cm_admin to create catalog entries.')
        );
    END IF;
    
    -- Get distinct arc subtypes from campaign
    v_querytext := format(
        'SELECT DISTINCT lower(T3.arc_type) AS subtype
         FROM cm.om_campaign_x_arc T1
         JOIN PARENT_SCHEMA.arc T2 ON T1.arc_id::text = T2.arc_id::text
         JOIN PARENT_SCHEMA.cat_arc T3 ON T2.arccat_id = T3.id
         WHERE T2.arccat_id IS NOT NULL AND T1.campaign_id = %L',
        v_campaign_id
    );
    
    FOR v_rec_subtype IN EXECUTE v_querytext
    LOOP
        v_subtype := v_rec_subtype.subtype;
        v_form_name := 'PARENT_SCHEMA_' || v_subtype;
        
        -- Check combinations of dnom, matcat_id, pnom against cat_arc for this subtype
        BEGIN
            -- First check if the table exists
            EXECUTE format('SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = %L)', v_form_name) INTO v_view_exists;
            
            IF NOT v_view_exists THEN
                v_log := v_log || 'WARNING: Table ' || v_form_name || ' does not exist. Skipping catalog check for subtype ' || v_subtype || chr(10);
                CONTINUE;
            END IF;
            
            v_querytext := format(
                'SELECT DISTINCT T1.arc_id, T2.cat_dnom, T2.cat_matcat_id, T2.cat_pnom
                 FROM cm.om_campaign_x_arc T1
                 JOIN %I T2 ON T1.arc_id::text = T2.arc_id::text
                 WHERE T2.cat_dnom IS NOT NULL AND T2.cat_matcat_id IS NOT NULL AND T2.cat_pnom IS NOT NULL AND T1.campaign_id = %L',
                v_form_name, v_campaign_id
            );
            
            FOR v_feature_record IN EXECUTE v_querytext
            LOOP
                v_feature_id := v_feature_record.arc_id;
                v_combination_key := v_feature_record.cat_dnom || '|' || v_feature_record.cat_matcat_id || '|' || v_feature_record.cat_pnom;
                
                -- Skip if already processed
                IF v_combination_key = ANY(v_processed_combinations) THEN
                    CONTINUE;
                END IF;
                
                SELECT COUNT(*) INTO v_count
                FROM PARENT_SCHEMA.cat_arc 
                WHERE dnom = v_feature_record.cat_dnom 
                  AND matcat_id = v_feature_record.cat_matcat_id 
                  AND pnom = v_feature_record.cat_pnom;
                
                IF v_count = 0 THEN
                    IF v_from_production THEN
                        -- Create new catalog entry in production
                        v_new_catalog_id := v_feature_record.cat_matcat_id || '_' || v_feature_record.cat_dnom || '_' || v_feature_record.cat_pnom;
                        INSERT INTO PARENT_SCHEMA.cat_arc (id, arctype_id, matcat_id, pnom, dnom, descript)
                        VALUES (v_new_catalog_id, v_subtype, v_feature_record.cat_matcat_id, v_feature_record.cat_pnom, v_feature_record.cat_dnom, 
                               'Auto-generated catalog entry for ' || v_subtype || ' - ' || v_feature_record.cat_matcat_id || ' ' || v_feature_record.cat_dnom || ' ' || v_feature_record.cat_pnom)
                        ON CONFLICT (id) DO NOTHING;
                        
                        v_log := v_log || 'INFO: For arc ID ' || v_feature_id || ' (subtype ' || v_subtype || 
                                 ') - Created new catalog entry with ID: ' || v_new_catalog_id || chr(10);
                        v_new_needed_count := v_new_needed_count + 1;
                    ELSE
                        v_log := v_log || 'INFO: For arc ID ' || v_feature_id || ' (subtype ' || v_subtype || 
                                 ') - A new catalog entry will be created when added to production. ' ||
                                 'Combination: dnom=' || v_feature_record.cat_dnom || 
                                 ', matcat_id=' || v_feature_record.cat_matcat_id || 
                                 ', pnom=' || v_feature_record.cat_pnom || chr(10);
                        v_new_needed_count := v_new_needed_count + 1;
                    END IF;
                    
                    -- Add to processed combinations
                    v_processed_combinations := array_append(v_processed_combinations, v_combination_key);
                END IF;
            END LOOP;
        EXCEPTION WHEN OTHERS THEN
            v_log := v_log || 'WARNING: Could not process arc subtype ' || v_subtype || ' - ' || SQLERRM || chr(10);
        END;
    END LOOP;
    
    -- Get distinct arc subtypes from lot
    v_querytext := format(
        'SELECT DISTINCT lower(T3.arc_type) AS subtype
         FROM cm.om_campaign_lot_x_arc T1
         JOIN PARENT_SCHEMA.arc T2 ON T1.arc_id::text = T2.arc_id::text
         JOIN PARENT_SCHEMA.cat_arc T3 ON T2.arccat_id = T3.id
         WHERE T2.arccat_id IS NOT NULL AND T1.lot_id = %L',
        v_lot_id
    );
    
    FOR v_rec_subtype IN EXECUTE v_querytext
    LOOP
        v_subtype := v_rec_subtype.subtype;
        v_form_name := 'PARENT_SCHEMA_' || v_subtype;
        
        -- Check combinations of dnom, matcat_id, pnom against cat_arc for this subtype
        BEGIN
            -- First check if the table exists
            EXECUTE format('SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = %L)', v_form_name) INTO v_view_exists;
            
            IF NOT v_view_exists THEN
                v_log := v_log || 'WARNING: Table ' || v_form_name || ' does not exist. Skipping catalog check for subtype ' || v_subtype || chr(10);
                CONTINUE;
            END IF;
            
            v_querytext := format(
                'SELECT DISTINCT T1.arc_id, T2.cat_dnom, T2.cat_matcat_id, T2.cat_pnom
                 FROM cm.om_campaign_lot_x_arc T1
                 JOIN %I T2 ON T1.arc_id::text = T2.arc_id::text
                 WHERE T2.cat_dnom IS NOT NULL AND T2.cat_matcat_id IS NOT NULL AND T2.cat_pnom IS NOT NULL AND T1.lot_id = %L',
                v_form_name, v_lot_id
            );
            
            FOR v_feature_record IN EXECUTE v_querytext
            LOOP
                v_feature_id := v_feature_record.arc_id;
                v_combination_key := v_feature_record.cat_dnom || '|' || v_feature_record.cat_matcat_id || '|' || v_feature_record.cat_pnom;
                
                -- Skip if already processed
                IF v_combination_key = ANY(v_processed_combinations) THEN
                    CONTINUE;
                END IF;
                
                SELECT COUNT(*) INTO v_count
                FROM PARENT_SCHEMA.cat_arc 
                WHERE dnom = v_feature_record.cat_dnom 
                  AND matcat_id = v_feature_record.cat_matcat_id 
                  AND pnom = v_feature_record.cat_pnom;
                
                IF v_count = 0 THEN
                    IF v_from_production THEN
                        -- Create new catalog entry in production
                        v_new_catalog_id := v_feature_record.cat_matcat_id || '_' || v_feature_record.cat_dnom || '_' || v_feature_record.cat_pnom;
                        INSERT INTO PARENT_SCHEMA.cat_arc (id, arctype_id, matcat_id, pnom, dnom, descript)
                        VALUES (v_new_catalog_id, v_subtype, v_feature_record.cat_matcat_id, v_feature_record.cat_pnom, v_feature_record.cat_dnom, 
                               'Auto-generated catalog entry for ' || v_subtype || ' - ' || v_feature_record.cat_matcat_id || ' ' || v_feature_record.cat_dnom || ' ' || v_feature_record.cat_pnom)
                        ON CONFLICT (id) DO NOTHING;
                        
                        v_log := v_log || 'INFO: For arc ID ' || v_feature_id || ' (subtype ' || v_subtype || 
                                 ') - Created new catalog entry with ID: ' || v_new_catalog_id || chr(10);
                        v_new_needed_count := v_new_needed_count + 1;
                    ELSE
                        v_log := v_log || 'INFO: For arc ID ' || v_feature_id || ' (subtype ' || v_subtype || 
                                 ') - A new catalog entry will be created when added to production. ' ||
                                 'Combination: dnom=' || v_feature_record.cat_dnom || 
                                 ', matcat_id=' || v_feature_record.cat_matcat_id || 
                                 ', pnom=' || v_feature_record.cat_pnom || chr(10);
                        v_new_needed_count := v_new_needed_count + 1;
                    END IF;
                    
                    -- Add to processed combinations
                    v_processed_combinations := array_append(v_processed_combinations, v_combination_key);
                END IF;
            END LOOP;
        EXCEPTION WHEN OTHERS THEN
            v_log := v_log || 'WARNING: Could not process arc subtype ' || v_subtype || ' - ' || SQLERRM || chr(10);
        END;
    END LOOP;
    
    -- Get distinct node subtypes from campaign
    v_querytext := format(
        'SELECT DISTINCT lower(T3.node_type) AS subtype
         FROM cm.om_campaign_x_node T1
         JOIN PARENT_SCHEMA.node T2 ON T1.node_id::text = T2.node_id::text
         JOIN PARENT_SCHEMA.cat_node T3 ON T2.nodecat_id = T3.id
         WHERE T2.nodecat_id IS NOT NULL AND T1.campaign_id = %L',
        v_campaign_id
    );
    
    FOR v_rec_subtype IN EXECUTE v_querytext
    LOOP
        v_subtype := v_rec_subtype.subtype;
        v_form_name := 'PARENT_SCHEMA_' || v_subtype;
        
        -- Check combinations of node_type, matcat_id, dnom against cat_node for this subtype
        BEGIN
            -- First check if the table exists
            EXECUTE format('SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = %L)', v_form_name) INTO v_view_exists;
            
            IF NOT v_view_exists THEN
                v_log := v_log || 'WARNING: Table ' || v_form_name || ' does not exist. Skipping catalog check for subtype ' || v_subtype || chr(10);
                CONTINUE;
            END IF;
            
            v_querytext := format(
                'SELECT DISTINCT T1.node_id, T2.node_type, T2.cat_matcat_id, T2.cat_dnom
                 FROM cm.om_campaign_x_node T1
                 JOIN cm.%I T2 ON T1.node_id::text = T2.node_id::text
                 WHERE T2.node_type IS NOT NULL AND T2.cat_matcat_id IS NOT NULL AND T2.cat_dnom IS NOT NULL AND T1.campaign_id = %L',
                v_form_name, v_campaign_id
            );
            
            FOR v_feature_record IN EXECUTE v_querytext
            LOOP
                v_feature_id := v_feature_record.node_id;
                v_combination_key := v_feature_record.node_type || '|' || v_feature_record.cat_matcat_id || '|' || v_feature_record.cat_dnom;
                
                -- Skip if already processed
                IF v_combination_key = ANY(v_processed_combinations) THEN
                    CONTINUE;
                END IF;
                
                SELECT COUNT(*) INTO v_count
                FROM PARENT_SCHEMA.cat_node 
                WHERE node_type = v_feature_record.node_type 
                  AND matcat_id = v_feature_record.cat_matcat_id 
                  AND dnom = v_feature_record.cat_dnom;
                
                IF v_count = 0 THEN
                    IF v_from_production THEN
                        -- Create new catalog entry in production
                        v_new_catalog_id := v_feature_record.cat_matcat_id || '_' || v_feature_record.cat_dnom || '_' || v_feature_record.node_type;
                        INSERT INTO PARENT_SCHEMA.cat_node (id, node_type, matcat_id, dnom, descript)
                        VALUES (v_new_catalog_id, v_feature_record.node_type, v_feature_record.cat_matcat_id, v_feature_record.cat_dnom, 
                               'Auto-generated catalog entry for ' || v_subtype || ' - ' || v_feature_record.cat_matcat_id || ' ' || v_feature_record.cat_dnom || ' ' || v_feature_record.node_type)
                        ON CONFLICT (id) DO NOTHING;
                        
                        v_log := v_log || 'INFO: For node ID ' || v_feature_id || ' (subtype ' || v_subtype || 
                                 ') - Created new catalog entry with ID: ' || v_new_catalog_id || chr(10);
                        v_new_needed_count := v_new_needed_count + 1;
                    ELSE
                        v_log := v_log || 'INFO: For node ID ' || v_feature_id || ' (subtype ' || v_subtype || 
                                 ') - A new catalog entry will be created when added to production. ' ||
                                 'Combination: node_type=' || v_feature_record.node_type || 
                                 ', matcat_id=' || v_feature_record.cat_matcat_id || 
                                 ', dnom=' || v_feature_record.cat_dnom || chr(10);
                        v_new_needed_count := v_new_needed_count + 1;
                    END IF;
                    
                    -- Add to processed combinations
                    v_processed_combinations := array_append(v_processed_combinations, v_combination_key);
                END IF;
            END LOOP;
        EXCEPTION WHEN OTHERS THEN
            v_log := v_log || 'WARNING: Could not process node subtype ' || v_subtype || ' - ' || SQLERRM || chr(10);
        END;
    END LOOP;
    
    -- Get distinct node subtypes from lot
    v_querytext := format(
        'SELECT DISTINCT lower(T3.node_type) AS subtype
         FROM cm.om_campaign_lot_x_node T1
         JOIN PARENT_SCHEMA.node T2 ON T1.node_id::text = T2.node_id::text
         JOIN PARENT_SCHEMA.cat_node T3 ON T2.nodecat_id = T3.id
         WHERE T2.nodecat_id IS NOT NULL AND T1.lot_id = %L',
        v_lot_id
    );
    
    FOR v_rec_subtype IN EXECUTE v_querytext
    LOOP
        v_subtype := v_rec_subtype.subtype;
        v_form_name := 'PARENT_SCHEMA_' || v_subtype;
        
        -- For lot tables, we can only check matcat_id and dnom combinations since node_type is not available
        BEGIN
            -- First check if the table exists
            EXECUTE format('SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = %L)', v_form_name) INTO v_view_exists;
            
            IF NOT v_view_exists THEN
                v_log := v_log || 'WARNING: Table ' || v_form_name || ' does not exist. Skipping catalog check for subtype ' || v_subtype || chr(10);
                CONTINUE;
            END IF;
            
            v_querytext := format(
                'SELECT DISTINCT T1.node_id, T2.node_type, T2.cat_matcat_id, T2.cat_dnom
                 FROM cm.om_campaign_lot_x_node T1
                 JOIN %I T2 ON T1.node_id::text = T2.node_id::text
                 WHERE T2.node_type IS NOT NULL AND T2.cat_matcat_id IS NOT NULL AND T2.cat_dnom IS NOT NULL AND T1.lot_id = %L',
                v_form_name, v_lot_id
            );
            
            FOR v_feature_record IN EXECUTE v_querytext
            LOOP
                v_feature_id := v_feature_record.node_id;
                v_combination_key := v_feature_record.node_type || '|' || v_feature_record.cat_matcat_id || '|' || v_feature_record.cat_dnom;
                
                -- Skip if already processed
                IF v_combination_key = ANY(v_processed_combinations) THEN
                    CONTINUE;
                END IF;
                
                -- Check if this combination exists in any cat_node entry
                SELECT COUNT(*) INTO v_count
                FROM PARENT_SCHEMA.cat_node 
                WHERE node_type = v_feature_record.node_type 
                  AND matcat_id = v_feature_record.cat_matcat_id 
                  AND dnom = v_feature_record.cat_dnom;
                
                IF v_count = 0 THEN
                    IF v_from_production THEN
                        -- Create new catalog entry in production
                        v_new_catalog_id := v_feature_record.cat_matcat_id || '_' || v_feature_record.cat_dnom || '_' || v_feature_record.node_type;
                        INSERT INTO PARENT_SCHEMA.cat_node (id, node_type, matcat_id, dnom, descript)
                        VALUES (v_new_catalog_id, v_feature_record.node_type, v_feature_record.cat_matcat_id, v_feature_record.cat_dnom, 
                               'Auto-generated catalog entry for ' || v_subtype || ' - ' || v_feature_record.cat_matcat_id || ' ' || v_feature_record.cat_dnom || ' ' || v_feature_record.node_type)
                        ON CONFLICT (id) DO NOTHING;
                        
                        v_log := v_log || 'INFO: For node ID ' || v_feature_id || ' (subtype ' || v_subtype || 
                                 ') - Created new catalog entry with ID: ' || v_new_catalog_id || chr(10);
                        v_new_needed_count := v_new_needed_count + 1;
                    ELSE
                        v_log := v_log || 'INFO: For node ID ' || v_feature_id || ' (subtype ' || v_subtype || 
                                 ') - A new catalog entry will be created when added to production. ' ||
                                 'Combination: node_type=' || v_feature_record.node_type || 
                                 ', matcat_id=' || v_feature_record.cat_matcat_id || 
                                 ', dnom=' || v_feature_record.cat_dnom || chr(10);
                        v_new_needed_count := v_new_needed_count + 1;
                    END IF;
                    
                    -- Add to processed combinations
                    v_processed_combinations := array_append(v_processed_combinations, v_combination_key);
                END IF;
            END LOOP;
        EXCEPTION WHEN OTHERS THEN
            v_log := v_log || 'WARNING: Could not process node subtype ' || v_subtype || ' - ' || SQLERRM || chr(10);
        END;
    END LOOP;
    
    -- Check if there are any errors in the log
    IF v_log LIKE '%ERROR:%' THEN
        v_result := json_build_object(
            'status', 'Failed',
            'message', 'Catalog validation found missing combinations',
            'body', json_build_object('log', v_log)
        );
    ELSE
        -- Add final summary message
        IF v_new_needed_count > 0 THEN
            v_log := v_log || format('INFO: %s catalog entr%s will be created when added to production.',
                                      v_new_needed_count,
                                      CASE WHEN v_new_needed_count = 1 THEN 'y' ELSE 'ies' END) || chr(10);
        ELSIF v_new_needed_count = 0 THEN
            v_log := v_log || 'INFO: All selected features have existing catalog entries - no new catalogs needed.' || chr(10);
        ELSE
            v_log := v_log || 'INFO: No catalog combinations were found to validate.' || chr(10);
        END IF;
        
        v_result := json_build_object(
            'status', 'Accepted',
            'message', 'Catalog validation completed',
            'body', json_build_object('log', v_log)
        );
    END IF;
    
    -- Restore previous search_path before returning
    PERFORM set_config('search_path', v_prev_search_path, true);
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
    -- Ensure restoration on error
    PERFORM set_config('search_path', v_prev_search_path, true);
    RETURN json_build_object(
        'status', 'Failed',
        'message', 'Unexpected error in catalog check: ' || SQLERRM,
        'body', json_build_object('log', v_log || 'ERROR: ' || SQLERRM || chr(10) || v_error_context)
    );
    
END;
$BODY$
LANGUAGE plpgsql; 
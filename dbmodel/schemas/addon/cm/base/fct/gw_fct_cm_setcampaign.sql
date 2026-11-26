/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3450

CREATE OR REPLACE FUNCTION cm.gw_fct_cm_setcampaign(p_data json)
  RETURNS json AS
$BODY$

DECLARE
    v_status TEXT := 'Accepted';
    v_message JSON;
    v_version TEXT;
    v_fields JSON;
    v_client JSON;
    v_campaign_type INT;
    v_reviewclass_id INT;
    v_visitclass_id INT;
    v_querytext TEXT;
    v_schemaname TEXT;
    v_id INTEGER;
    v_newid INTEGER;
    v_exists INTEGER;
    v_cols TEXT;
    v_vals TEXT;
    v_sets TEXT;
    v_rec RECORD;
    v_prev_search_path text;

BEGIN
    -- Set search path transaction-locally and remember previous
    v_prev_search_path := current_setting('search_path');
    PERFORM set_config('search_path', 'cm,public', true);
    v_schemaname = 'cm';

    -- Get version
    SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

    -- Parse input
    v_client := (p_data ->> 'client')::json;
    v_fields := (p_data -> 'data' ->> 'fields')::json;
    v_campaign_type := (p_data -> 'data' ->> 'campaign_type')::int;
    IF (p_data -> 'data' -> 'fields' ->> 'campaign_id') IS NOT NULL THEN
        v_id := (p_data -> 'data' -> 'fields' ->> 'campaign_id')::int;
    END IF;

    -- Parse class ID
    IF v_campaign_type = 1 THEN
        v_reviewclass_id := (v_fields ->> 'reviewclass_id')::int;
    ELSIF v_campaign_type = 2 THEN
        v_visitclass_id := (v_fields ->> 'visitclass_id')::int;
    END IF;

    -- Check if the campaign ID exists
    SELECT campaign_id INTO v_exists FROM om_campaign WHERE campaign_id = v_id;

    -- DYNAMICALLY BUILD THE QUERY
    v_cols := '';
    v_vals := '';
    v_sets := '';

    FOR v_rec IN SELECT * FROM json_each_text(v_fields)
    LOOP
        -- Exclude subtype-specific fields and campaign_type, which are handled manually
        IF v_rec.key IN ('reviewclass_id', 'visitclass_id', 'campaign_type') THEN
            CONTINUE;
        END IF;

        -- For INSERT
        v_cols := v_cols || ', ' || v_rec.key;
        
        -- Handle data types for values
        IF v_rec.key IN ('startdate', 'enddate', 'real_startdate', 'real_enddate') THEN
            v_vals := v_vals || ', ' || quote_nullable(v_rec.value) || '::date';
        ELSIF v_rec.key = 'active' THEN
             v_vals := v_vals || ', ' || (v_rec.value)::boolean;
        ELSE
            v_vals := v_vals || ', ' || quote_nullable(v_rec.value);
        END IF;

        -- For UPDATE
        IF v_rec.key != 'campaign_id' THEN
            IF v_rec.key IN ('startdate', 'enddate', 'real_startdate', 'real_enddate') THEN
                v_sets := v_sets || ', ' || v_rec.key || ' = ' || quote_nullable(v_rec.value) || '::date';
            ELSIF v_rec.key = 'active' THEN
                v_sets := v_sets || ', ' || v_rec.key || ' = ' || (v_rec.value)::boolean;
            ELSE
                v_sets := v_sets || ', ' || v_rec.key || ' = ' || quote_nullable(v_rec.value);
            END IF;
        END IF;
    END LOOP;

    -- Remove leading commas
    v_cols := substr(v_cols, 3);
    v_vals := substr(v_vals, 3);
    v_sets := substr(v_sets, 3);

    -- Add campaign_type, which is handled outside the loop
    v_cols := v_cols || ', campaign_type';
    v_vals := v_vals || ', ' || v_campaign_type;
    v_sets := v_sets || ', campaign_type = ' || v_campaign_type;

    IF v_exists IS NULL THEN
        -- INSERT
        v_querytext := 'INSERT INTO om_campaign (' || v_cols || ') VALUES (' || v_vals || ') RETURNING campaign_id';
        EXECUTE v_querytext INTO v_newid;

        -- Insert into subtype table
        IF v_campaign_type = 1 THEN
            INSERT INTO om_campaign_review (campaign_id, reviewclass_id)
            VALUES (v_newid, v_reviewclass_id);
        ELSIF v_campaign_type = 2 THEN
            INSERT INTO om_campaign_visit (campaign_id, visitclass_id)
            VALUES (v_newid, v_visitclass_id);
        ELSIF v_campaign_type = 3 THEN
            INSERT INTO om_campaign_inventory (campaign_id)
            VALUES (v_newid);
        END IF;

    ELSE
        -- UPDATE
        v_querytext := 'UPDATE om_campaign SET ' || v_sets || ' WHERE campaign_id = ' || v_id || ' RETURNING campaign_id';
        EXECUTE v_querytext INTO v_newid;

        -- For updates, we might need to update the subtype table as well
        IF v_campaign_type = 1 THEN
            UPDATE om_campaign_review SET reviewclass_id = v_reviewclass_id WHERE campaign_id = v_newid;
        ELSIF v_campaign_type = 2 THEN
            UPDATE om_campaign_visit SET visitclass_id = v_visitclass_id WHERE campaign_id = v_newid;
        ELSIF v_campaign_type = 3 THEN
            -- For inventory campaigns, the om_campaign_inventory table doesn't have additional fields to update
            -- Just ensure the record exists
            INSERT INTO om_campaign_inventory (campaign_id) 
            VALUES (v_newid) 
            ON CONFLICT (campaign_id) DO NOTHING;
        END IF;
    END IF;

    -- Update selector_campaign for manager users for selected organization and admin users
    EXECUTE 'INSERT INTO selector_campaign (campaign_id, cur_user)
    select '|| v_newid ||', username from cat_user
    join cat_team using (team_id) 
    where (role_id=''role_addon_cm_manager'' and organization_id = ' || quote_nullable(v_fields ->> 'organization_id') || ')
    OR (role_id=''role_addon_cm_admin'')
    ON CONFLICT DO NOTHING;';

	PERFORM cm.gw_fct_cm_polygon_geom(json_build_object('id', v_newid, 'name', 'campaign'));

    -- Return success response
    PERFORM set_config('search_path', v_prev_search_path, true);
    RETURN json_build_object(
        'status', v_status,
        'message', 'Campaign saved successfully',
        'version', v_version,
        'body', json_build_object('campaign_id', v_newid)
    );

EXCEPTION WHEN OTHERS THEN
    PERFORM set_config('search_path', v_prev_search_path, true);
    RETURN json_build_object(
        'status', 'Failed',
        'NOSQLERR', SQLERRM,
        'SQLSTATE', SQLSTATE,
        'version', v_version
    );
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

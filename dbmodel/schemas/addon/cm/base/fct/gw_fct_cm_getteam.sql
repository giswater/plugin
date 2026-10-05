/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3434

CREATE OR REPLACE FUNCTION cm.gw_fct_cm_getteam(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_campaign_id integer;
    v_result json;
   v_orgname TEXT;
   v_prev_search_path text;
   v_empty_body json;
BEGIN

    -- Extract campaign_id from the input JSON
    v_campaign_id := (p_data->>'p_campaign_id')::integer;
   RAISE NOTICE 'v_campaign_id:: %', v_campaign_id;

    -- Set transaction-local search_path
    v_prev_search_path := current_setting('search_path');
    PERFORM set_config('search_path', 'cm,public', true);

    -- If no campaign_id is found, return empty
    IF v_campaign_id IS NULL THEN
        PERFORM set_config('search_path', v_prev_search_path, true);
        RETURN '{"status": "Accepted", "body": {"data": []}}'::json;
    END IF;

   SELECT orgname INTO v_orgname
   FROM cm.om_campaign oc
   JOIN cm.cat_organization co ON co.organization_id = oc.organization_id
   WHERE oc.campaign_id = v_campaign_id;

  -- Assumed that OWNER text is the administrators
  	IF v_orgname = 'OWNER' THEN
    	-- Return teams that match the criteria
	    SELECT json_build_object(
	        'status', 'Accepted',
	        'body', json_build_object(
                'organization_name', v_orgname,
	        	'data', json_agg(
	            	json_build_object('id', ct.team_id, 'idval', ct.teamname)
	        	)
	        )
	    )
	    INTO v_result
	    FROM cm.cat_team AS ct
	    WHERE ct.role_id <> 'role_cm_admin'; -- ASSUMED
	ELSE
		-- Return teams that match the criteria
	    SELECT json_build_object(
	        'status', 'Accepted',
	        'body', json_build_object(
                'organization_name', v_orgname,
	        	'data', json_agg(
	            	json_build_object('id', ct.team_id, 'idval', ct.teamname)
	        	)
	        )
	    )
	    INTO v_result
	    FROM cm.cat_team AS ct
	    JOIN cm.om_campaign AS oc ON ct.organization_id = oc.organization_id
	    WHERE oc.campaign_id = v_campaign_id
	   	AND ct.role_id = 'role_cm_field'; -- ASSUMED
     END IF;

     RAISE NOTICE 'v_result->: %', v_result->'body'->'data';

    -- Keep organization_name even when the campaign has no matching teams
    v_empty_body := json_build_object(
        'status', 'Accepted',
        'body', json_build_object(
            'organization_name', v_orgname,
            'data', json_build_array(json_build_object('id', '', 'idval', ''))
        )
    );

    IF v_result->'body'->>'data' IS NULL THEN
        PERFORM set_config('search_path', v_prev_search_path, true);
    	RETURN v_empty_body;
	ELSE
        PERFORM set_config('search_path', v_prev_search_path, true);
	    RETURN COALESCE(v_result, v_empty_body);
	END IF;


EXCEPTION WHEN OTHERS THEN
    PERFORM set_config('search_path', v_prev_search_path, true);
    RAISE;
END;
$function$
;

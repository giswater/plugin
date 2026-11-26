/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3464

CREATE OR REPLACE FUNCTION cm.gw_trg_cm_update_selectors()
  RETURNS trigger AS
$BODY$

DECLARE
    rec RECORD;
   	selector_name TEXT;
  	table_name TEXT;
    v_prev_search_path text;
BEGIN
	v_prev_search_path := current_setting('search_path');
	PERFORM set_config('search_path', format('%I, public', TG_TABLE_SCHEMA), true);
    selector_name := TG_ARGV[0];

	IF selector_name = 'campaign' THEN

		IF TG_OP = 'INSERT' THEN

		    FOR rec IN
		        SELECT DISTINCT cu.username AS cur_user
				FROM om_campaign oc
				JOIN cat_team ct ON ct.organization_id = oc.organization_id
				JOIN cat_user cu USING(team_id)
				WHERE ct.role_id IN ('role_addon_cm_admin', 'role_addon_cm_manager')
				AND oc.campaign_id = NEW.campaign_id
		    LOOP
		        INSERT INTO selector_campaign (campaign_id, cur_user)
		        VALUES (
		            NEW.campaign_id,
		            rec.cur_user
		        ) ON CONFLICT DO NOTHING;
		    END LOOP;

			PERFORM set_config('search_path', v_prev_search_path, true);
			RETURN NEW;

		ELSIF TG_OP = 'UPDATE' THEN

			IF NEW.organization_id != OLD.organization_id THEN
			    DELETE FROM selector_campaign WHERE campaign_id = OLD.campaign_id;

				FOR rec IN
			        SELECT DISTINCT cu.username AS cur_user
					FROM om_campaign oc
					JOIN cat_team ct ON ct.organization_id = oc.organization_id
					JOIN cat_user cu USING(team_id)
					WHERE ct.role_id IN ('role_addon_cm_admin', 'role_addon_cm_manager')
					AND oc.campaign_id = NEW.campaign_id
			    LOOP
			        INSERT INTO selector_campaign (campaign_id, cur_user)
			        VALUES (
			            NEW.campaign_id,
			            rec.cur_user
			        ) ON CONFLICT DO NOTHING;
			    END LOOP;
			END IF;

			PERFORM set_config('search_path', v_prev_search_path, true);
			RETURN NEW;

		ELSIF TG_OP = 'DELETE' THEN
		    DELETE FROM selector_campaign WHERE campaign_id = OLD.campaign_id;
		    	PERFORM set_config('search_path', v_prev_search_path, true);
		    	RETURN NULL;

		END IF;

	ELSIF selector_name = 'campaign_lot' THEN

		IF TG_OP = 'INSERT' THEN

		    FOR rec IN
		        SELECT DISTINCT cu.username AS cur_user
				FROM om_campaign oc
				JOIN cat_team ct ON ct.organization_id = oc.organization_id
				JOIN cat_user cu USING(team_id)
				WHERE ct.role_id = 'role_addon_cm_admin'
				   OR (ct.role_id = 'role_addon_cm_manager')
				   OR (ct.role_id = 'role_addon_cm_field' AND ct.team_id = NEW.team_id)
				AND oc.campaign_id = NEW.campaign_id
		    LOOP
		        INSERT INTO selector_lot (lot_id, cur_user)
		        VALUES (
		            NEW.lot_id,
		            rec.cur_user
		        ) ON CONFLICT DO NOTHING;
		    END LOOP;

			PERFORM set_config('search_path', v_prev_search_path, true);
			RETURN NEW;

		ELSIF TG_OP = 'UPDATE' THEN

			IF NEW.campaign_id != OLD.campaign_id OR NEW.team_id != OLD.team_id THEN
			    DELETE FROM selector_lot WHERE lot_id = OLD.lot_id;

				FOR rec IN
			        SELECT DISTINCT cu.username AS cur_user
					FROM om_campaign oc
					JOIN cat_team ct ON ct.organization_id = oc.organization_id
					JOIN cat_user cu USING(team_id)
					WHERE ct.role_id = 'role_addon_cm_admin'
					   OR (ct.role_id = 'role_addon_cm_manager')
					   OR (ct.role_id = 'role_addon_cm_field' AND ct.team_id = NEW.team_id)
					AND oc.campaign_id = NEW.campaign_id
			    LOOP
			        INSERT INTO selector_lot (lot_id, cur_user)
			        VALUES (
			            NEW.lot_id,
			            rec.cur_user
			        ) ON CONFLICT DO NOTHING;
			    END LOOP;
			END IF;

			PERFORM set_config('search_path', v_prev_search_path, true);
			RETURN NEW;

		ELSIF TG_OP = 'DELETE' THEN
		   DELETE FROM selector_lot WHERE lot_id = OLD.lot_id;

		    	PERFORM set_config('search_path', v_prev_search_path, true);
		    	RETURN NULL;

		END IF;

	END IF;

	PERFORM set_config('search_path', v_prev_search_path, true);
	RETURN NEW;

EXCEPTION WHEN OTHERS THEN
    PERFORM set_config('search_path', v_prev_search_path, true);
    RAISE;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

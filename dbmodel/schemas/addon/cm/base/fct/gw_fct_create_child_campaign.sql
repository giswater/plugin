/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION cm.gw_fct_create_child_campaign(v_parent_campaign_id integer)
RETURNS json AS
$BODY$
DECLARE
	v_version text;
	v_prev_search_path text;
	v_parent record;
	v_child_count integer;
	v_non_integrated_count integer;
	v_new_id integer;
	v_name text;
	v_reviewclass_id integer;
	v_visitclass_id integer;
	v_inventoryclass_id integer;
	v_feature_type text;
	v_ids integer[];
	v_feature_types text[] := ARRAY['arc', 'node', 'connec', 'link', 'gully'];
	v_table_exists boolean;
	v_parent_lot_ids int4[];

BEGIN
	v_prev_search_path := current_setting('search_path');
	PERFORM set_config('search_path', 'cm, public', true);

	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- Load parent campaign
	SELECT * INTO v_parent
	FROM om_campaign
	WHERE campaign_id = v_parent_campaign_id;

	IF NOT FOUND THEN
		PERFORM set_config('search_path', v_prev_search_path, true);
		RETURN json_build_object(
			'status', 'Failed',
			'message', format('Parent campaign %s not found', v_parent_campaign_id),
			'version', v_version
		);
	END IF;

	-- Parent must be integrated (status = 9 ACCEPTED)
	IF v_parent.status IS DISTINCT FROM 9 THEN
		PERFORM set_config('search_path', v_prev_search_path, true);
		RETURN json_build_object(
			'status', 'Failed',
			'message', format('Parent campaign %s is not integrated (status must be 9 ACCEPTED)', v_parent_campaign_id),
			'version', v_version
		);
	END IF;

	-- Existing children must also be integrated
	SELECT count(*) INTO v_non_integrated_count
	FROM om_campaign
	WHERE parent_id = v_parent_campaign_id
	  AND status IS DISTINCT FROM 9;

	IF v_non_integrated_count > 0 THEN
		PERFORM set_config('search_path', v_prev_search_path, true);
		RETURN json_build_object(
			'status', 'Failed',
			'message', format(
				'Parent campaign %s has %s child campaign(s) that are not integrated',
				v_parent_campaign_id,
				v_non_integrated_count
			),
			'version', v_version
		);
	END IF;

	SELECT array_agg(lot_id)
	INTO v_parent_lot_ids
	FROM om_campaign_lot
	WHERE campaign_id = v_parent_campaign_id
	OR campaign_id IN (
		SELECT campaign_id
		FROM om_campaign
		WHERE parent_id = v_parent_campaign_id
	);

	SELECT count(*) INTO v_child_count
	FROM om_campaign
	WHERE parent_id = v_parent_campaign_id;

	v_name := v_parent.name || ' - Recatastro ' || (v_child_count + 1);

	-- Create child campaign
	INSERT INTO om_campaign (
		name,
		startdate,
		enddate,
		real_startdate,
		real_enddate,
		campaign_type,
		active,
		organization_id,
		status,
		expl_id,
		sector_id,
		parent_id,
		the_geom
	)
	VALUES (
		v_name,
		v_parent.startdate,
		v_parent.enddate,
		now()::date,
		NULL,
		v_parent.campaign_type,
		true,
		v_parent.organization_id,
		1,
		v_parent.expl_id,
		v_parent.sector_id,
		v_parent_campaign_id,
		v_parent.the_geom
	)
	RETURNING campaign_id INTO v_new_id;

	-- Copy subtype row from parent
	IF v_parent.campaign_type = 1 THEN
		SELECT reviewclass_id INTO v_reviewclass_id
		FROM om_campaign_review
		WHERE campaign_id = v_parent_campaign_id;

		INSERT INTO om_campaign_review (campaign_id, reviewclass_id)
		VALUES (v_new_id, v_reviewclass_id);
	ELSIF v_parent.campaign_type = 2 THEN
		SELECT visitclass_id INTO v_visitclass_id
		FROM om_campaign_visit
		WHERE campaign_id = v_parent_campaign_id;

		INSERT INTO om_campaign_visit (campaign_id, visitclass_id)
		VALUES (v_new_id, v_visitclass_id);
	ELSIF v_parent.campaign_type = 3 THEN
		SELECT inventoryclass_id INTO v_inventoryclass_id
		FROM om_campaign_inventory
		WHERE campaign_id = v_parent_campaign_id;

		INSERT INTO om_campaign_inventory (campaign_id, inventoryclass_id)
		VALUES (v_new_id, v_inventoryclass_id);
	END IF;

	-- Selector for managers of organization + admins
	INSERT INTO selector_campaign (campaign_id, cur_user)
	SELECT v_new_id, username
	FROM cat_user
	JOIN cat_team USING (team_id)
	WHERE (role_id = 'role_cm_manager' AND organization_id = v_parent.organization_id)
	   OR role_id = 'role_cm_admin'
	ON CONFLICT DO NOTHING;

	-- Copy features from parent campaign_x_* tables
	FOREACH v_feature_type IN ARRAY v_feature_types
	LOOP
		PERFORM set_config('search_path', 'cm, public', true);

		SELECT EXISTS (
			SELECT 1
			FROM information_schema.tables
			WHERE table_schema = 'cm'
			  AND table_name = 'om_campaign_x_' || v_feature_type
		) INTO v_table_exists;

		IF NOT v_table_exists THEN
			CONTINUE;
		END IF;

		EXECUTE format(
			'SELECT array_agg(p.%I) FROM cm.om_campaign_lot_x_%I c JOIN PARENT_SCHEMA.%I p ON c.integrated_id = p.%I WHERE lot_id = ANY($1) AND p.state = 1',
			concat(v_feature_type, '_id'),
			v_feature_type,
			v_feature_type,
			concat(v_feature_type, '_id')
		)
		INTO v_ids
		USING v_parent_lot_ids;



		IF v_ids IS NULL OR array_length(v_ids, 1) IS NULL THEN
			CONTINUE;
		END IF;

		PERFORM PARENT_SCHEMA.gw_fct_manage_inserts_by_ids(
			v_new_id,
			'campaign',
			v_feature_type,
			v_ids
		);
	END LOOP;

	PERFORM set_config('search_path', v_prev_search_path, true);
	RETURN json_build_object(
		'status', 'Accepted',
		'message', 'Child campaign created successfully',
		'version', v_version,
		'body', json_build_object(
			'campaign_id', v_new_id,
			'parent_id', v_parent_campaign_id,
			'name', v_name
		)
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
LANGUAGE plpgsql VOLATILE;

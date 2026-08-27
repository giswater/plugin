/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3472

--DROP FUNCTION IF EXISTS cm.gw_trg_cm_campaign_x_feature_validate_type() CASCADE;
CREATE OR REPLACE FUNCTION cm.gw_trg_cm_campaign_x_feature_validate_type()
 RETURNS trigger AS
$BODY$

DECLARE
    v_feature TEXT := TG_ARGV[0];
    v_feature_types_allowed json;
    v_feature_type TEXT;
    v_allowed boolean;
    v_object_id TEXT;
    v_sql TEXT;
	v_new_feature BOOLEAN := false;


BEGIN
	IF TG_OP = 'INSERT' THEN
		-- Exception for new feature coming from other app, using a '-' id
		EXECUTE format('SELECT ($1).%I_id::text LIKE ''-%%''', v_feature)
		INTO v_new_feature
		USING NEW;
	
		IF v_new_feature THEN
		    RETURN NEW;
		END IF;
	
	    -- Get allowed object_ids (feature_type list)
	    SELECT to_json(array_agg(object_id)) INTO v_feature_types_allowed
	    FROM cm.om_campaign oc
	    JOIN cm.om_campaign_review ocr ON oc.campaign_id = ocr.campaign_id
	    JOIN cm.om_reviewclass_x_object orxo ON ocr.reviewclass_id = orxo.reviewclass_id
	    WHERE oc.campaign_id = NEW.campaign_id;
	
	    -- Get the dynamic ID value from NEW
	    EXECUTE format('SELECT ($1).%I', v_feature || '_id')
	    INTO v_object_id
	    USING NEW;
	
	
	    -- Get the feature type (dynamic)
	    v_sql := format(
	        'SELECT c.%I_type
	         FROM PARENT_SCHEMA.%I p 
	         JOIN PARENT_SCHEMA.cat_%I c ON p.%Icat_id = c.id 
	         WHERE p.%I_id = $1::integer',
	        v_feature, v_feature, v_feature, v_feature, v_feature
	    );
	
	    EXECUTE v_sql
	    INTO v_feature_type
	    USING v_object_id;
	
	    -- Check if allowed
	    SELECT EXISTS (
	        SELECT 1
	        FROM json_array_elements_text(v_feature_types_allowed) AS t(object_id)
	        WHERE t.object_id = v_feature_type
	    )
	    INTO v_allowed;
	
		-- Set lock_level to 3 if positive id
	    IF v_object_id::int > 0 AND TG_WHEN = 'AFTER' THEN
	        EXECUTE format('UPDATE PARENT_SCHEMA.%I SET lock_level = 3 WHERE %I_id = $1::integer', v_feature, v_feature)
	        USING v_object_id;
	    END IF;
	
	
	    -- If not allowed, skip insert
	    IF NOT v_allowed THEN
	        RAISE NOTICE 'Insert skipped → feature_type not allowed.';
	        RETURN NULL;
	    END IF;
	
	    RAISE NOTICE 'Insert accepted → feature_type allowed.';
	    RETURN NEW;

	ELSIF TG_OP = 'DELETE' THEN

		EXECUTE format('SELECT ($1).%I_id::text LIKE ''-%%''', v_feature)
		INTO v_new_feature
		USING OLD;
	
		IF v_new_feature IS NULL THEN
		    RETURN NULL;
		END IF;

		EXECUTE format('SELECT ($1).%I', v_feature || '_id')
	    INTO v_object_id
	    USING OLD;

		IF v_object_id::int > 0 THEN
            EXECUTE format('UPDATE PARENT_SCHEMA.%I SET lock_level = NULL WHERE %I_id = $1::integer', v_feature, v_feature)
            USING v_object_id;
        END IF;
		RETURN OLD;
	END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
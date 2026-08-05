/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = cm, public, pg_catalog;

ALTER TABLE cm.om_campaign ADD COLUMN IF NOT EXISTS parent_id integer NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE table_schema = 'cm'
          AND table_name = 'om_campaign'
          AND constraint_name = 'om_campaign_parent_id_fkey'
    ) THEN
        ALTER TABLE cm.om_campaign
            ADD CONSTRAINT om_campaign_parent_id_fkey
            FOREIGN KEY (parent_id) REFERENCES cm.om_campaign(campaign_id)
            ON UPDATE CASCADE ON DELETE RESTRICT;
    END IF;
END $$;

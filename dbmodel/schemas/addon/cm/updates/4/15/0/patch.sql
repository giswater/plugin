/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = cm, public, pg_catalog;

ALTER TABLE cm.om_campaign_lot_x_node ADD COLUMN integrated_id int4 NULL;
ALTER TABLE cm.om_campaign_lot_x_arc ADD COLUMN integrated_id int4 NULL;
ALTER TABLE cm.om_campaign_lot_x_link ADD COLUMN integrated_id int4 NULL;
ALTER TABLE cm.om_campaign_lot_x_connec ADD COLUMN integrated_id int4 NULL;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'cm' AND table_name = 'om_campaign_lot_x_gully'
    ) THEN
        ALTER TABLE cm.om_campaign_lot_x_gully ADD COLUMN integrated_id int4 NULL;
    END IF;
END $$;

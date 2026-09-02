/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = cibs, public, pg_catalog;

ALTER TABLE cibs.hydrometer ADD brand_id varchar(50) NULL;
ALTER TABLE cibs.hydrometer ADD model_id varchar(50) NULL;

CREATE OR REPLACE VIEW v_hydrometer AS
SELECT * FROM cibs.hydrometer;

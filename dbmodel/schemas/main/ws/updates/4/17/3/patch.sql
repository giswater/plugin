/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

UPDATE config_form_list
SET query_text = REPLACE(query_text, 'hydrometer_customer_code', 'hydro_customer_code')
WHERE query_text ILIKE '%hydrometer_customer_code%';

DELETE FROM config_form_tableview
WHERE columnname = 'hydrometer_customer_code';

UPDATE config_form_tableview
SET addparam = CASE
      WHEN addparam IS NULL THEN NULL
      ELSE REPLACE(addparam::text, 'hydrometer_customer_code', 'hydro_customer_code')::json
    END
WHERE objectname = 'tbl_mincut_hydro'
  AND columnname = 'hydro_customer_code';

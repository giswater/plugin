/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- Toolbox 2118 (build nodes from arc vertices): node type combo, alphabetical
UPDATE config_toolbox
SET inputparams = replace(
    inputparams::text,
    'where cfn.id is not null',
    'where cfn.id is not null order by cfn.id'
)::json
WHERE id = 2118
  AND inputparams::text ILIKE '%where cfn.id is not null%'
  AND inputparams::text NOT ILIKE '%order by cfn.id%';

UPDATE config_form_fields
SET dv_isnullvalue = true
WHERE columnname = 'ownercat_id'
  AND formname ILIKE 've_element%';

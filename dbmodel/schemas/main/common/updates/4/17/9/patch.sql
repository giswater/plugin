/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

INSERT INTO config_info_layer (layer_id, is_parent, is_editable, formtemplate, headertext, orderby, tableparentepa_id, addparam)
SELECT 've_man_genelem', is_parent, is_editable, formtemplate, 'Element', orderby, tableparentepa_id, addparam
FROM config_info_layer
WHERE layer_id = 've_man_frelem'
ON CONFLICT (layer_id) DO NOTHING;

INSERT INTO config_info_layer (layer_id, is_parent, is_editable, formtemplate, headertext, orderby)
SELECT 've_man_genelem', false, true, 'info_feature', 'Element', 4
WHERE NOT EXISTS (SELECT 1 FROM config_info_layer WHERE layer_id = 've_man_genelem');

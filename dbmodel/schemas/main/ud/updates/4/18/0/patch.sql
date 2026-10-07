/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- Expose graph_delimiter on ve_cat_feature_node (UD was missing it vs WS) (#966)
-- Append graph_delimiter (CREATE OR REPLACE cannot insert a column mid-list)
CREATE OR REPLACE VIEW ve_cat_feature_node
AS SELECT cat_feature.id,
    cat_feature.feature_class AS system_id,
    cat_feature_node.epa_default,
    cat_feature_node.isarcdivide,
    cat_feature_node.isprofilesurface,
    cat_feature.code_autofill,
    cat_feature_node.choose_hemisphere,
    cat_feature_node.double_geom::text AS double_geom,
    cat_feature_node.num_arcs,
    cat_feature_node.isexitupperintro,
    cat_feature.shortcut_key,
    cat_feature.link_path,
    cat_feature.descript,
    cat_feature.active,
    cat_feature.abbreviation,
    cat_feature.custom_code_autofill,
    cat_feature_node.graph_delimiter
   FROM cat_feature
     JOIN cat_feature_node USING (id);

INSERT INTO config_form_fields (formname, formtype, tabname, columnname, "datatype", widgettype, "label", tooltip,
	ismandatory, isparent, iseditable, isautoupdate, hidden)
VALUES ('ve_cat_feature_node', 'form_feature', 'tab_none', 'graph_delimiter', 'string', 'text',
	'Graph delimiter:', 'Graph delimiter', false, false, true, false, false)
ON CONFLICT (formname, formtype, columnname, tabname) DO NOTHING;

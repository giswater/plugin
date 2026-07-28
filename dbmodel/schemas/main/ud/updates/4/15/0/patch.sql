/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"SAVE-DROP", "rootViews":["ve_gully"], "saveRoots":true, "batchId":1}}$$);

ALTER TABLE gully ALTER COLUMN dataquality_obs TYPE text[] USING (dataquality_obs::text)::text[];

SELECT gw_fct_admin_manage_view_dependencies($${"data":{"action":"RESTORE", "batchId":1}}$$);

-- pg2epa geographic SRID validation: gw_fct_pg2epa_main (step 1), gw_fct_pg2epa_export_inp and gw_fct_pg2epa_dump_subcatch (base/fct, applied via load_base / reload_fct_ftrg).

INSERT INTO config_mapzones (id, abrevation, descript, fid, code_autofill, active, is_dynamic) VALUES
('DWFZONE', 'DWF', 'Drainage Water Flow Zone', 481, true, true, true),
('DRAINZONE', 'DRA', 'Drainage Zone', 481, true, true, false);

CREATE OR REPLACE VIEW ve_cat_feature_arc
AS SELECT cat_feature.id,
    cat_feature.feature_class AS system_id,
    cat_feature_arc.epa_default,
    cat_feature.code_autofill,
    cat_feature.shortcut_key,
    cat_feature.link_path,
    cat_feature.descript,
    cat_feature.active,
    cat_feature.abrevation
   FROM cat_feature
     JOIN cat_feature_arc USING (id);

CREATE OR REPLACE VIEW ve_cat_feature_connec
AS SELECT cat_feature.id,
    cat_feature.feature_class AS system_id,
    cat_feature.code_autofill,
    cat_feature_connec.double_geom::text AS double_geom,
    cat_feature.shortcut_key,
    cat_feature.link_path,
    cat_feature.descript,
    cat_feature.active,
    cat_feature.abrevation
   FROM cat_feature
     JOIN cat_feature_connec USING (id);

CREATE OR REPLACE VIEW ve_cat_feature_element
AS SELECT cat_feature.id,
    cat_feature.feature_class AS system_id,
    cat_feature_element.epa_default,
    cat_feature.code_autofill,
    cat_feature.shortcut_key,
    cat_feature.link_path,
    cat_feature.descript,
    cat_feature.active,
    cat_feature.abrevation
   FROM cat_feature
     JOIN cat_feature_element USING (id);

CREATE OR REPLACE VIEW ve_cat_feature_gully
AS SELECT cat_feature.id,
    cat_feature.feature_class AS system_id,
    cat_feature_gully.epa_default,
    cat_feature.code_autofill,
    cat_feature_gully.double_geom::text AS double_geom,
    cat_feature.shortcut_key,
    cat_feature.link_path,
    cat_feature.descript,
    cat_feature.active,
    cat_feature.abrevation
   FROM cat_feature
     JOIN cat_feature_gully USING (id);

CREATE OR REPLACE VIEW ve_cat_feature_link
AS SELECT cat_feature.id,
    cat_feature.feature_class AS system_id,
    cat_feature.code_autofill,
    cat_feature.shortcut_key,
    cat_feature.link_path,
    cat_feature.descript,
    cat_feature.active,
    cat_feature.abrevation
   FROM cat_feature
     JOIN cat_feature_link USING (id);

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
    cat_feature.abrevation
   FROM cat_feature
     JOIN cat_feature_node USING (id);

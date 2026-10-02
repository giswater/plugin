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

CREATE OR REPLACE VIEW v_om_visit
AS SELECT DISTINCT ON (visit_id) visit_id,
    code,
    visitcat_id,
    name,
    visit_start,
    visit_end,
    user_name,
    is_done,
    feature_id,
    feature_type,
    feature_class,
    featurecat_id,
    feature_state,
    the_geom
   FROM ( SELECT om_visit.id AS visit_id,
            om_visit.ext_code AS code,
            om_visit.visitcat_id,
            om_visit_cat.name,
            om_visit.startdate AS visit_start,
            om_visit.enddate AS visit_end,
            om_visit.user_name,
            om_visit.is_done,
            om_visit_x_node.node_id AS feature_id,
            'NODE'::text AS feature_type,
            cat_feature.feature_class,
            node.nodecat_id AS featurecat_id,
            node.state AS feature_state,
                CASE
                    WHEN om_visit.the_geom IS NULL THEN node.the_geom
                    ELSE om_visit.the_geom
                END AS the_geom
           FROM om_visit
             JOIN om_visit_x_node ON om_visit_x_node.visit_id = om_visit.id
             JOIN node ON node.node_id = om_visit_x_node.node_id
             JOIN vf_node vf ON vf.node_id = node.node_id
             JOIN om_visit_cat ON om_visit.visitcat_id = om_visit_cat.id
             JOIN cat_node ON cat_node.id::text = node.nodecat_id::text
             JOIN cat_feature ON cat_feature.id::text = cat_node.node_type::text
        UNION
         SELECT om_visit.id AS visit_id,
            om_visit.ext_code AS code,
            om_visit.visitcat_id,
            om_visit_cat.name,
            om_visit.startdate AS visit_start,
            om_visit.enddate AS visit_end,
            om_visit.user_name,
            om_visit.is_done,
            om_visit_x_arc.arc_id AS feature_id,
            'ARC'::text AS feature_type,
            cat_feature.feature_class,
            arc.arccat_id AS featurecat_id,
            arc.state AS feature_state,
                CASE
                    WHEN om_visit.the_geom IS NULL THEN st_lineinterpolatepoint(arc.the_geom, 0.5::double precision)
                    ELSE om_visit.the_geom
                END AS the_geom
           FROM om_visit
             JOIN om_visit_x_arc ON om_visit_x_arc.visit_id = om_visit.id
             JOIN arc ON arc.arc_id = om_visit_x_arc.arc_id
             JOIN vf_arc vf ON vf.arc_id = arc.arc_id
             JOIN om_visit_cat ON om_visit.visitcat_id = om_visit_cat.id
             JOIN cat_arc ON cat_arc.id::text = arc.arccat_id::text
             JOIN cat_feature ON cat_feature.id::text = cat_arc.arc_type::text
        UNION
         SELECT om_visit.id AS visit_id,
            om_visit.ext_code AS code,
            om_visit.visitcat_id,
            om_visit_cat.name,
            om_visit.startdate AS visit_start,
            om_visit.enddate AS visit_end,
            om_visit.user_name,
            om_visit.is_done,
            om_visit_x_connec.connec_id AS feature_id,
            'CONNEC'::text AS feature_type,
            cat_feature.feature_class,
            connec.conneccat_id AS featurecat_id,
            connec.state AS feature_state,
                CASE
                    WHEN om_visit.the_geom IS NULL THEN connec.the_geom
                    ELSE om_visit.the_geom
                END AS the_geom
           FROM om_visit
             JOIN om_visit_x_connec ON om_visit_x_connec.visit_id = om_visit.id
             JOIN connec ON connec.connec_id = om_visit_x_connec.connec_id
             JOIN vf_connec vf ON vf.connec_id = connec.connec_id
             JOIN om_visit_cat ON om_visit.visitcat_id = om_visit_cat.id
             JOIN cat_connec ON cat_connec.id::text = connec.conneccat_id::text
             JOIN cat_feature ON cat_feature.id::text = cat_connec.connec_type::text
        UNION
         SELECT om_visit.id AS visit_id,
            om_visit.ext_code AS code,
            om_visit.visitcat_id,
            om_visit_cat.name,
            om_visit.startdate AS visit_start,
            om_visit.enddate AS visit_end,
            om_visit.user_name,
            om_visit.is_done,
            om_visit_x_link.link_id AS feature_id,
            'LINK'::text AS feature_type,
            cat_feature.feature_class,
            link.linkcat_id AS featurecat_id,
            link.state AS feature_state,
                CASE
                    WHEN om_visit.the_geom IS NULL THEN st_lineinterpolatepoint(link.the_geom, 0.5::double precision)
                    ELSE om_visit.the_geom
                END AS the_geom
           FROM om_visit
             JOIN om_visit_x_link ON om_visit_x_link.visit_id = om_visit.id
             JOIN link ON link.link_id = om_visit_x_link.link_id
             JOIN vf_link vf ON vf.link_id = link.link_id
             JOIN om_visit_cat ON om_visit.visitcat_id = om_visit_cat.id
             JOIN cat_link ON cat_link.id::text = link.linkcat_id::text
             JOIN cat_feature ON cat_feature.id::text = cat_link.link_type::text) a;

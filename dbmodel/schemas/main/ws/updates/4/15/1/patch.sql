/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

CREATE OR REPLACE VIEW v_om_mincut_initpoint
AS WITH sel_mincut_result AS (
         SELECT selector_mincut_result.result_id,
            selector_mincut_result.result_type
           FROM selector_mincut_result
          WHERE selector_mincut_result.cur_user = CURRENT_USER
        )
 SELECT om.id,
    om.work_order,
    a.idval AS state,
    b.idval AS class,
    om.mincut_type,
    om.received_date,
    om.expl_id,
    exploitation.name AS expl_name,
    macroexploitation.name AS macroexpl_name,
    om.macroexpl_id,
    om.muni_id,
    v_municipality.name AS muni_name,
    om.postcode,
    om.streetaxis_id,
    v_streetaxis.name AS street_name,
    om.postnumber,
    c.idval AS anl_cause,
    om.anl_tstamp,
    om.anl_user,
    om.anl_descript,
    om.anl_feature_id,
    om.anl_feature_type,
    om.anl_the_geom,
    om.forecast_start,
    om.forecast_end,
    om.assigned_to,
    om.exec_start,
    om.exec_end,
    om.exec_user,
    om.exec_descript,
    om.exec_from_plot,
    om.exec_depth,
    om.exec_appropiate,
    om.notified,
    om.output,
    sm.result_type,
    om.shutoff_required
FROM om_mincut om
JOIN sel_mincut_result sm ON sm.result_id = om.id
LEFT JOIN om_typevalue a ON a.id::integer = om.mincut_state AND a.typevalue = 'mincut_state'::text
LEFT JOIN om_typevalue b ON b.id::integer = om.mincut_class AND b.typevalue = 'mincut_class'::text
LEFT JOIN om_typevalue c ON c.id::integer = om.anl_cause::integer AND c.typevalue = 'mincut_cause'::text
LEFT JOIN exploitation ON om.expl_id = exploitation.expl_id
LEFT JOIN v_streetaxis ON om.streetaxis_id::text = v_streetaxis.id::text
LEFT JOIN macroexploitation ON om.macroexpl_id = macroexploitation.macroexpl_id
LEFT JOIN v_municipality ON om.muni_id = v_municipality.muni_id;

/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- Same resolution as gw_fct_pg2epa_fill_data: arc material, then inp_conduit.custom_n, then catalog material.
-- Only CONDUIT arcs write Manning n into the SWMM [CONDUITS] section.
INSERT INTO sys_fprocess (fid, fprocess_name, project_type, parameters, "source", isaudit, fprocess_type, addparam, except_level, except_msg, except_table, except_table_msg, query_text, info_msg, function_name, active)
VALUES(
    734,
    'Check conduits with null Manning n',
    'ud',
    NULL,
    'core',
    true,
    'Check epa-config',
    NULL,
    3,
    'conduits with null Manning roughness (n). Fill cat_material.n or inp_conduit.custom_n.',
    'anl_arc',
    NULL,
    'SELECT a.arc_id, a.arccat_id, a.expl_id, a.the_geom
FROM t_arc a
JOIN cat_arc ca ON ca.id = a.arccat_id
LEFT JOIN cat_material cma ON cma.id = a.matcat_id
LEFT JOIN cat_material cm ON cm.id = ca.matcat_id
LEFT JOIN inp_conduit ic ON ic.arc_id = a.arc_id
WHERE a.epa_type = ''CONDUIT''
AND COALESCE(cma.n, ic.custom_n, cm.n) IS NULL',
    'Manning roughness (n) is filled for every conduit from the arc material, custom_n or the catalog material.',
    '[gw_fct_pg2epa_check_data]',
    true
) ON CONFLICT (fid) DO NOTHING;

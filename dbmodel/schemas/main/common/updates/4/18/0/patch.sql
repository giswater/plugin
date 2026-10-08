/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;

-- Persist mapzone synoptic layout from gw_fct_graphanalytics_mapzones_v1 (#965)
-- synoptic_geom uses abstract Sugiyama coords (no project SRID), same space as attrib.synopticGeometry
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"mapzone_graph",
  "column":"synoptic_id", "dataType":"int4"}}$$);
SELECT gw_fct_admin_manage_fields($${"data":{"action":"ADD","table":"mapzone_graph",
  "column":"synoptic_geom", "dataType":"geometry(LineString)"}}$$);

CREATE INDEX IF NOT EXISTS mapzone_graph_synoptic_id_idx ON mapzone_graph USING btree (synoptic_id);

INSERT INTO config_param_system (
    parameter, value, descript, label, isenabled, layoutorder, project_type,
    dv_isparent, isautoupdate, datatype, widgettype, ismandatory, iseditable, layoutname
)
VALUES (
    'edit_element_geom_from_feature', 'false',
    'If true, a new element without geometry takes a point from the associated feature, and an element that shares a node, connec or gully point follows that feature when it moves. Flow regulators (FRELEM) are excluded. Arcs and links use the midpoint of the line.',
    'Copy element geometry from feature:',
    true, 12, 'utils', false, false, 'boolean', 'check', false, true, 'lyt_topology'
)
ON CONFLICT (parameter) DO NOTHING;

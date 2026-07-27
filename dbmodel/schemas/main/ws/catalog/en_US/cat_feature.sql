/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = "SCHEMA_NAME", public, pg_catalog;

-- Replace catalog seeded by updates with locale-specific naming conventions.

DELETE FROM cat_element;
DELETE FROM cat_link;
DELETE FROM cat_connec;
DELETE FROM cat_arc;
DELETE FROM cat_node;
DELETE FROM cat_feature_element;
DELETE FROM cat_feature_link;
DELETE FROM cat_feature_connec;
DELETE FROM cat_feature_arc;
DELETE FROM cat_feature_node;
DELETE FROM cat_feature;

DELETE FROM cat_material;

-- Legacy _type columns exist until lastprocess; disable trigger for explicit catalog seed.
ALTER TABLE cat_feature_arc DROP COLUMN IF EXISTS _type;
ALTER TABLE cat_feature_node DROP COLUMN IF EXISTS _type;
ALTER TABLE cat_feature_connec DROP COLUMN IF EXISTS _type;

ALTER TABLE cat_feature DISABLE TRIGGER gw_trg_cat_feature_after;

INSERT INTO cat_material (id, descript) VALUES 
('FE', 'Iron'),
('FD', 'Ductile iron'),
('FG', 'Gray cast iron'),
('PE', 'Polyethylene'),
('PVC', 'PVC'),
('FC', 'Fiberglass'),
('DESC', 'Unknown'),
('HOR', 'Concrete'),
('ACER', 'Steel')
ON CONFLICT (id) DO UPDATE SET descript = EXCLUDED.descript;

INSERT INTO cat_feature (id, feature_class, feature_type, active, parent_layer, child_layer) VALUES
('CHKV', 'VALVE', 'NODE', TRUE, 've_node', 've_node_chkv'),
('AIRV', 'VALVE', 'NODE', TRUE, 've_node', 've_node_airv'),
('FCV', 'VALVE', 'NODE', TRUE, 've_node', 've_node_fcv'),
('PRV', 'VALVE', 'NODE', TRUE, 've_node', 've_node_prv'),
('DRAINV', 'VALVE', 'NODE', TRUE, 've_node', 've_node_drainv'),
('ISOLAV', 'VALVE', 'NODE', TRUE, 've_node', 've_node_isolav'),
('PSV', 'VALVE', 'NODE', TRUE, 've_node', 've_node_psv'),
('REDUCTION', 'REDUCTION', 'NODE', TRUE, 've_node', 've_node_reduction'),
('HYDRANT', 'HYDRANT', 'NODE', TRUE, 've_node', 've_node_hydrant'),
('NETSERVCON', 'NETWJOIN', 'NODE', FALSE, 've_node', 've_node_netservcon'),
('ENDNODE', 'JUNCTION', 'NODE', FALSE, 've_node', 've_node_endnode'),
('WWELL', 'WATERWELL', 'NODE', FALSE, 've_node', 've_node_wwell'),
('WTP', 'WTP', 'NODE', TRUE, 've_node', 've_node_wtp'),
('JUNCTION', 'JUNCTION', 'NODE', TRUE, 've_node', 've_node_junction'),
('INTAKE', 'SOURCE', 'NODE', FALSE, 've_node', 've_node_intake'),
('FILTER', 'FILTER', 'NODE', FALSE, 've_node', 've_node_filter'),
('NETIRHYDR', 'NETWJOIN', 'NODE', FALSE, 've_node', 've_node_netirhydr'),
('PUMP', 'PUMP', 'NODE', TRUE, 've_node', 've_node_pump'),
('TANK', 'TANK', 'NODE', TRUE, 've_node', 've_node_tank'),
('FLOWMETER', 'METER', 'NODE', TRUE, 've_node', 've_node_flowmeter'),
('PRESSMETER', 'METER', 'NODE', FALSE, 've_node', 've_node_pressmeter'),
('PIPE', 'PIPE', 'ARC', TRUE, 've_arc', 've_arc_pipe'),
('VARC', 'VARC', 'ARC', TRUE, 've_arc', 've_arc_varc'),
('LINK', 'PIPELINK', 'LINK', TRUE, 've_link', 've_link_link'),
('VILINK', 'VLINK', 'LINK', FALSE, 've_link', 've_link_vilink'),
('TAP', 'TAP', 'CONNEC', TRUE, 've_connec', 've_connec_tap'),
('ORNAMENTAL', 'FOUNTAIN', 'CONNEC', FALSE, 've_connec', 've_connec_ornamental'),
('IRHYDRANT', 'GREENTAP', 'CONNEC', FALSE, 've_connec', 've_connec_irhydrant'),
('SERVCON', 'WJOIN', 'CONNEC', TRUE, 've_connec', 've_connec_servcon'),
('VISERVCON', 'VCONNEC', 'CONNEC', FALSE, 've_connec', 've_connec_vservcon'),
('COVER', 'GENELEM', 'ELEMENT', TRUE, 've_element', 've_element_cover'),
('EPUMP', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_epump'),
('EVALVE', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_evalve'),
('EMETER', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_emeter')
ON CONFLICT (id) DO UPDATE SET feature_class = EXCLUDED.feature_class, feature_type = EXCLUDED.feature_type, active = EXCLUDED.active, parent_layer = EXCLUDED.parent_layer, child_layer = EXCLUDED.child_layer;


INSERT INTO cat_feature_node (id, epa_default, isarcdivide, graph_delimiter) VALUES
('CHKV', 'JUNCTION', TRUE, '{NONE}'),
('AIRV', 'UNDEFINED', FALSE, '{NONE}'),
('FCV', 'VALVE', TRUE, '{NONE}'),
('PRV', 'VALVE', TRUE, '{PRESSZONE}'),
('DRAINV', 'JUNCTION', TRUE, '{NONE}'),
('ISOLAV', 'SHORTPIPE', TRUE, '{NONE}'),
('PSV', 'VALVE', TRUE, '{NONE}'),
('REDUCTION', 'JUNCTION', TRUE, '{NONE}'),
('HYDRANT', 'JUNCTION', TRUE, '{NONE}'),
('NETSERVCON', 'JUNCTION', TRUE, '{NONE}'),
('ENDNODE', 'JUNCTION', TRUE, '{NONE}'),
('WWELL', 'RESERVOIR', TRUE, '{SECTOR}'),
('WTP', 'RESERVOIR', TRUE, '{SECTOR}'),
('JUNCTION', 'JUNCTION', TRUE, '{NONE}'),
('INTAKE', 'RESERVOIR', TRUE, '{SECTOR}'),
('FILTER', 'JUNCTION', TRUE, '{NONE}'),
('NETIRHYDR', 'JUNCTION', TRUE, '{NONE}'),
('PUMP', 'PUMP', TRUE, '{PRESSZONE}'),
('TANK', 'TANK', TRUE, '{SECTOR, DMA, PRESSZONE}'),
('FLOWMETER', 'SHORTPIPE', TRUE, '{DMA}'),
('PRESSMETER', 'JUNCTION', TRUE, '{NONE}')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default, isarcdivide = EXCLUDED.isarcdivide, graph_delimiter = EXCLUDED.graph_delimiter;

INSERT INTO cat_feature_arc (id, epa_default) VALUES
('PIPE', 'PIPE'),
('VARC', 'PIPE')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;

INSERT INTO cat_feature_link (id) VALUES
('LINK'),
('VILINK')
ON CONFLICT (id) DO NOTHING;

INSERT INTO cat_feature_connec (id, epa_default) VALUES 
('TAP', 'JUNCTION'),
('ORNAMENTAL', 'JUNCTION'),
('IRHYDRANT', 'JUNCTION'),
('SERVCON', 'JUNCTION'),
('VISERVCON', 'JUNCTION')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;

INSERT INTO cat_feature_element (id, epa_default) VALUES
('COVER', 'UNDEFINED'),
('EPUMP', 'FRPUMP'),
('EVALVE', 'FRVALVE'),
('EMETER', 'FRSHORTPIPE')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;

INSERT INTO cat_node (id, node_type) VALUES
('CHKV', 'CHKV'),
('AIRV', 'AIRV'),
('FCV', 'FCV'),
('PRV', 'PRV'),
('DRAINV', 'DRAINV'),
('ISOLAV', 'ISOLAV'),
('PSV', 'PSV'),
('REDUCTION', 'REDUCTION'),
('HYDRANT', 'HYDRANT'),
('TOPSERVCON', 'NETSERVCON'),
('ENDNODE', 'ENDNODE'),
('WWELL', 'WWELL'),
('WTP', 'WTP'),
('JUNCTION', 'JUNCTION'),
('INTAKE', 'INTAKE'),
('FILTER', 'FILTER'),
('TOPIRHYDR', 'NETIRHYDR'),
('PUMP', 'PUMP'),
('TANK', 'TANK'),
('FLOWMETER', 'FLOWMETER'),
('PRESSMETER', 'PRESSMETER')
ON CONFLICT (id) DO UPDATE SET node_type = EXCLUDED.node_type;

INSERT INTO cat_arc (id, arc_type, matcat_id, dnom) VALUES
('PVC110', 'PIPE', 'PVC', 110),
('PVC160', 'PIPE', 'PVC', 160),
('PE63', 'PIPE', 'PE', 63),
('PE110', 'PIPE', 'PE', 110),
('PE160', 'PIPE', 'PE', 160),
('FD150', 'PIPE', 'FD', 150),
('FD200', 'PIPE', 'FD', 200),
('VARC', 'VARC', NULL, 0)
ON CONFLICT (id) DO UPDATE SET arc_type = EXCLUDED.arc_type, matcat_id = EXCLUDED.matcat_id, dnom = EXCLUDED.dnom;

INSERT INTO cat_connec (id, connec_type) VALUES
('FACADE', 'SERVCON'),
('HYDRO', 'SERVCON'),
('INDOOR', 'SERVCON'),
('CONST', 'SERVCON'),
('IRHYDRANT', 'IRHYDRANT'),
('TAP', 'TAP'),
('ORNAMENTAL', 'ORNAMENTAL'),
('VISERVCON', 'VISERVCON')
ON CONFLICT (id) DO UPDATE SET connec_type = EXCLUDED.connec_type;

INSERT INTO cat_link (id, link_type, matcat_id, dnom) VALUES
('PE25', 'LINK', 'PE', 25),
('PE32', 'LINK', 'PE', 32),
('PE50', 'LINK', 'PE', 50),
('VILINK', 'VILINK', NULL, 0)
ON CONFLICT (id) DO UPDATE SET link_type = EXCLUDED.link_type, matcat_id = EXCLUDED.matcat_id, dnom = EXCLUDED.dnom;

INSERT INTO cat_element (id, element_type) VALUES
('COVER40X40', 'COVER'),
('COVER60X60', 'COVER')
ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type;

ALTER TABLE cat_feature ENABLE TRIGGER gw_trg_cat_feature_after;


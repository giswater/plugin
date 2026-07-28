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
('FE', 'Ferro'),
('FD', 'Fosa de ferro'),
('FG', 'Fosa de ferro gris'),
('PE', 'Polietileno'),
('PVC', 'PVC'),
('FC', 'Fibra de vidre'),
('DESC', 'Desconegut'),
('HOR', 'Concret'),
('ACER', 'Acero')
ON CONFLICT (id) DO UPDATE SET descript = EXCLUDED.descript;

INSERT INTO cat_feature (id, feature_class, feature_type, active, parent_layer, child_layer) VALUES
('VANTIRET', 'VALVE', 'NODE', TRUE, 've_node', 've_node_vantiret'),
('VVENTOSA', 'VALVE', 'NODE', TRUE, 've_node', 've_node_vventosa'),
('VREGQ', 'VALVE', 'NODE', TRUE, 've_node', 've_node_vregq'),
('VRED', 'VALVE', 'NODE', TRUE, 've_node', 've_node_vred'),
('VDESC', 'VALVE', 'NODE', TRUE, 've_node', 've_node_vdesc'),
('VCOMP', 'VALVE', 'NODE', TRUE, 've_node', 've_node_vcomp'),
('VSOST', 'VALVE', 'NODE', TRUE, 've_node', 've_node_vsust'),
('REDUC', 'REDUCTION', 'NODE', TRUE, 've_node', 've_node_reduc'),
('HIDRANT', 'HYDRANT', 'NODE', TRUE, 've_node', 've_node_hydrant'),
('ESCOXAR', 'NETWJOIN', 'NODE', FALSE, 've_node', 've_node_escoxar'),
('FINAL', 'JUNCTION', 'NODE', FALSE, 've_node', 've_node_final'),
('POU', 'WATERWELL', 'NODE', FALSE, 've_node', 've_node_pou'),
('ETAP', 'WTP', 'NODE', TRUE, 've_node', 've_node_etap'),
('UNIO', 'JUNCTION', 'NODE', TRUE, 've_node', 've_node_unio'),
('CAPTACIO', 'SOURCE', 'NODE', FALSE, 've_node', 've_node_captacio'),
('FILTRE', 'FILTER', 'NODE', FALSE, 've_node', 've_node_filtre'),
('BREGXAR', 'NETWJOIN', 'NODE', FALSE, 've_node', 've_node_bregxar'),
('BOMBAMENT', 'PUMP', 'NODE', TRUE, 've_node', 've_node_bombament'),
('DIPOSIT', 'TANK', 'NODE', TRUE, 've_node', 've_node_diposit'),
('CABALIM', 'METER', 'NODE', TRUE, 've_node', 've_node_cabalim'),
('MESPRESS', 'METER', 'NODE', FALSE, 've_node', 've_node_mespress'),
('TRAM', 'PIPE', 'ARC', TRUE, 've_arc', 've_arc_tram'),
('TRAMV', 'VARC', 'ARC', TRUE, 've_arc', 've_arc_tramv'),
('RAMAL', 'PIPELINK', 'LINK', TRUE, 've_link', 've_link_ramal'),
('RAMALV', 'VLINK', 'LINK', FALSE, 've_link', 've_link_ramalv'),
('FONT', 'TAP', 'CONNEC', TRUE, 've_connec', 've_connec_font'),
('ORNAMENTAL', 'FOUNTAIN', 'CONNEC', FALSE, 've_connec', 've_connec_ornamental'),
('BREG', 'GREENTAP', 'CONNEC', FALSE, 've_connec', 've_connec_breg'),
('ESCOMESA', 'WJOIN', 'CONNEC', TRUE, 've_connec', 've_connec_escomesa'),
('ESCOMESAV', 'VCONNEC', 'CONNEC', FALSE, 've_connec', 've_connec_escomesav'),
('TAPA', 'GENELEM', 'ELEMENT', TRUE, 've_element', 've_element_tapa'),
('EPUMP', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_epump'),
('EVALVE', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_evalve'),
('EMETER', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_emeter')
ON CONFLICT (id) DO UPDATE SET feature_class = EXCLUDED.feature_class, feature_type = EXCLUDED.feature_type, active = EXCLUDED.active, parent_layer = EXCLUDED.parent_layer, child_layer = EXCLUDED.child_layer;


INSERT INTO cat_feature_node (id, epa_default, isarcdivide, graph_delimiter) VALUES
('VANTIRET', 'JUNCTION', TRUE, '{NONE}'),
('VVENTOSA', 'UNDEFINED', FALSE, '{NONE}'),
('VREGQ', 'VALVE', TRUE, '{NONE}'),
('VRED', 'VALVE', TRUE, '{PRESSZONE}'),
('VDESC', 'JUNCTION', TRUE, '{NONE}'),
('VCOMP', 'SHORTPIPE', TRUE, '{NONE}'),
('VSOST', 'VALVE', TRUE, '{NONE}'),
('REDUC', 'JUNCTION', TRUE, '{NONE}'),
('HIDRANT', 'JUNCTION', TRUE, '{NONE}'),
('ESCOXAR', 'JUNCTION', TRUE, '{NONE}'),
('FINAL', 'JUNCTION', TRUE, '{NONE}'),
('POU', 'RESERVOIR', TRUE, '{SECTOR}'),
('ETAP', 'RESERVOIR', TRUE, '{SECTOR}'),
('UNIO', 'JUNCTION', TRUE, '{NONE}'),
('CAPTACIO', 'RESERVOIR', TRUE, '{SECTOR}'),
('FILTRE', 'JUNCTION', TRUE, '{NONE}'),
('BREGXAR', 'JUNCTION', TRUE, '{NONE}'),
('BOMBAMENT', 'PUMP', TRUE, '{PRESSZONE}'),
('DIPOSIT', 'TANK', TRUE, '{SECTOR, DMA, PRESSZONE}'),
('CABALIM', 'SHORTPIPE', TRUE, '{DMA}'),
('MESPRESS', 'JUNCTION', TRUE, '{NONE}')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default, isarcdivide = EXCLUDED.isarcdivide, graph_delimiter = EXCLUDED.graph_delimiter;

INSERT INTO cat_feature_arc (id, epa_default) VALUES
('TRAM', 'PIPE'),
('TRAMV', 'PIPE')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;

INSERT INTO cat_feature_link (id) VALUES
('RAMAL'),
('RAMALV')
ON CONFLICT (id) DO NOTHING;

INSERT INTO cat_feature_connec (id, epa_default) VALUES 
('FONT', 'JUNCTION'),
('ORNAMENTAL', 'JUNCTION'),
('BREG', 'JUNCTION'),
('ESCOMESA', 'JUNCTION'),
('ESCOMESAV', 'JUNCTION')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;


INSERT INTO cat_feature_element (id, epa_default) VALUES
('TAPA', 'UNDEFINED'),
('EPUMP', 'FRPUMP'),
('EVALVE', 'FRVALVE'),
('EMETER', 'FRSHORTPIPE')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;

INSERT INTO cat_node (id, node_type) VALUES
('VANTIRET', 'VANTIRET'),
('VVENTOSA', 'VVENTOSA'),
('VREGQ', 'VREGQ'),
('VRED', 'VRED'),
('VDESC', 'VDESC'),
('VCOMP', 'VCOMP'),
('VSOST', 'VSOST'),
('REDUC', 'REDUC'),
('HIDRANT', 'HIDRANT'),
('ESCOXAR', 'ESCOXAR'),
('FINAL', 'FINAL'),
('POU', 'POU'),
('ETAP', 'ETAP'),
('UNIO', 'UNIO'),
('CAPTACIO', 'CAPTACIO'),
('FILTRE', 'FILTRE'),
('BREGTOP', 'BREGXAR'),
('BOMBAMENT', 'BOMBAMENT'),
('DIPOSIT', 'DIPOSIT'),
('CABALIM', 'CABALIM'),
('MESPRESS', 'MESPRESS')
ON CONFLICT (id) DO UPDATE SET node_type = EXCLUDED.node_type;

INSERT INTO cat_arc (id, arc_type, matcat_id, dnom) VALUES
('PVC110', 'TRAM', 'PVC', 110),
('PVC160', 'TRAM', 'PVC', 160),
('PE63', 'TRAM', 'PE', 63),
('PE110', 'TRAM', 'PE', 110),
('PE160', 'TRAM', 'PE', 160),
('FD150', 'TRAM', 'FD', 150),
('FD200', 'TRAM', 'FD', 200),
('TRAMV', 'TRAMV', NULL, 0)
ON CONFLICT (id) DO UPDATE SET arc_type = EXCLUDED.arc_type, matcat_id = EXCLUDED.matcat_id, dnom = EXCLUDED.dnom;

INSERT INTO cat_connec (id, connec_type) VALUES
('ARMARI', 'ESCOMESA'),
('COMPTADOR', 'ESCOMESA'),
('INTERIOR', 'ESCOMESA'),
('PROVISIONAL', 'ESCOMESA'),
('BREG', 'BREG'),
('FONT', 'FONT'),
('ORNAMENTAL', 'ORNAMENTAL'),
('ESCOMESAV', 'ESCOMESAV')
ON CONFLICT (id) DO UPDATE SET connec_type = EXCLUDED.connec_type;

INSERT INTO cat_link (id, link_type, matcat_id, dnom) VALUES
('PE25', 'RAMAL', 'PE', 25),
('PE32', 'RAMAL', 'PE', 32),
('PE50', 'RAMAL', 'PE', 50),
('RAMALV', 'RAMALV', NULL, 0)
ON CONFLICT (id) DO UPDATE SET link_type = EXCLUDED.link_type, matcat_id = EXCLUDED.matcat_id, dnom = EXCLUDED.dnom;

INSERT INTO cat_element (id, element_type, matcat_id) VALUES
('TAPA40X40', 'TAPA', 'FD'),
('TAPA60X60', 'TAPA', 'FD')
ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, matcat_id = EXCLUDED.matcat_id;

ALTER TABLE cat_feature ENABLE TRIGGER gw_trg_cat_feature_after;

